import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Asset store for managing media files with atomic writes and checksums
class AssetStore {
  static AssetStore? _instance;
  late Directory _baseDir;
  bool _initialized = false;

  AssetStore._();

  static AssetStore get instance {
    _instance ??= AssetStore._();
    return _instance!;
  }

  /// Initialize the asset store
  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(p.join(appDir.path, 'journal_assets'));

    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }

    _initialized = true;
  }

  /// Get the base directory path
  String get basePath => _baseDir.path;

  /// Get the path for a journal's assets
  String getJournalPath(String journalId) {
    return p.join(_baseDir.path, 'journals', journalId);
  }

  /// Get the path for a page's assets
  String getPagePath(String journalId, String pageId) {
    return p.join(getJournalPath(journalId), 'pages', pageId);
  }

  /// Get the path for a block's assets
  String getBlockPath(String journalId, String pageId, String blockId) {
    return p.join(getPagePath(journalId, pageId), 'blocks', blockId);
  }

  /// Write an image file atomically
  Future<AssetWriteResult> writeImage({
    required String journalId,
    required String pageId,
    required String blockId,
    required List<int> bytes,
    String extension = 'jpg',
  }) async {
    final dir = await _ensureDirectory(
      getBlockPath(journalId, pageId, blockId),
    );
    final fileName = '${blockId}_image.$extension';
    final filePath = p.join(dir.path, fileName);

    return _atomicWrite(filePath, bytes);
  }

  /// Write an ink file atomically
  Future<AssetWriteResult> writeInk({
    required String journalId,
    required String pageId,
    required String blockId,
    required List<int> bytes,
  }) async {
    final dir = await _ensureDirectory(
      getBlockPath(journalId, pageId, blockId),
    );
    final fileName = '${blockId}_ink.bin';
    final filePath = p.join(dir.path, fileName);

    return _atomicWrite(filePath, bytes);
  }

  /// Write a thumbnail file
  Future<AssetWriteResult> writeThumbnail({
    required String journalId,
    required String pageId,
    required List<int> bytes,
  }) async {
    final dir = await _ensureDirectory(
      p.join(getJournalPath(journalId), 'thumbs'),
    );
    final fileName = '$pageId.jpg';
    final filePath = p.join(dir.path, fileName);

    return _atomicWrite(filePath, bytes);
  }

  /// Read a file
  Future<List<int>?> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Verify file checksum
  Future<bool> verifyChecksum(String path, String expectedChecksum) async {
    final bytes = await readFile(path);
    if (bytes == null) return false;

    final actualChecksum = _calculateChecksum(bytes);
    return actualChecksum == expectedChecksum;
  }

  /// Calculate SHA-256 checksum
  String _calculateChecksum(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Ensure directory exists
  Future<Directory> _ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Atomic write: write to temp file, then rename
  Future<AssetWriteResult> _atomicWrite(
    String targetPath,
    List<int> bytes,
  ) async {
    final tempPath = '$targetPath.tmp';
    final tempFile = File(tempPath);

    try {
      // Write to temp file
      await tempFile.writeAsBytes(bytes, flush: true);

      // Calculate checksum
      final checksum = _calculateChecksum(bytes);

      // Rename to target (atomic on most file systems)
      await tempFile.rename(targetPath);

      return AssetWriteResult(
        path: targetPath,
        checksum: checksum,
        sizeBytes: bytes.length,
        success: true,
      );
    } catch (e) {
      // Clean up temp file if it exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return AssetWriteResult(
        path: targetPath,
        checksum: '',
        sizeBytes: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Clean up orphaned files for a deleted block
  Future<void> cleanupBlock({
    required String journalId,
    required String pageId,
    required String blockId,
  }) async {
    final blockDir = Directory(getBlockPath(journalId, pageId, blockId));
    if (await blockDir.exists()) {
      await blockDir.delete(recursive: true);
    }
  }

  /// Clean up all files for a deleted page
  Future<void> cleanupPage({
    required String journalId,
    required String pageId,
  }) async {
    final pageDir = Directory(getPagePath(journalId, pageId));
    if (await pageDir.exists()) {
      await pageDir.delete(recursive: true);
    }

    // Also delete thumbnail
    final thumbPath = p.join(
      getJournalPath(journalId),
      'thumbs',
      '$pageId.jpg',
    );
    await deleteFile(thumbPath);
  }

  /// Clean up all files for a deleted journal
  Future<void> cleanupJournal(String journalId) async {
    final journalDir = Directory(getJournalPath(journalId));
    if (await journalDir.exists()) {
      await journalDir.delete(recursive: true);
    }
  }
}

/// Result of an asset write operation
class AssetWriteResult {
  final String path;
  final String checksum;
  final int sizeBytes;
  final bool success;
  final String? error;

  AssetWriteResult({
    required this.path,
    required this.checksum,
    required this.sizeBytes,
    required this.success,
    this.error,
  });
}
