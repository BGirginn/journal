import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:path_provider/path_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  // DAOs
  final journalDao = ref.watch(journalDaoProvider);
  final pageDao = ref.watch(pageDaoProvider);
  final blockDao = ref.watch(blockDaoProvider);

  return SyncService(
    authService,
    storageService,
    journalDao,
    pageDao,
    blockDao,
  );
});

class SyncService {
  final AuthService _authService;
  final StorageService _storageService;
  final dynamic
  _journalDao; // Typing as dynamic to simplify dependency, ideally strict typed
  final dynamic _pageDao;
  final dynamic _blockDao;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SyncService(
    this._authService,
    this._storageService,
    this._journalDao,
    this._pageDao,
    this._blockDao,
  );

  String? get _userId => _authService.currentUser?.uid;

  Future<void> syncDown() async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('Sync: No user logged in.');
      return;
    }

    try {
      debugPrint('Sync: Starting...');

      // 1. Sync Journals
      final journalSnapshots = await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .get();

      for (final doc in journalSnapshots.docs) {
        final data = doc.data();
        final journal = Journal(
          id: data['id'],
          title: data['title'],
          coverStyle: data['coverStyle'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          deletedAt: data['deletedAt'] != null
              ? (data['deletedAt'] as Timestamp).toDate()
              : null,
        );

        // Upsert Journal
        await _journalDao.insertJournal(
          journal,
        ); // DAO should handle conflict usually via INSERT OR REPLACE

        // 2. Sync Pages for this Journal
        await _syncPages(uid, journal.id);
      }

      debugPrint('Sync: Completed.');
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> _syncPages(String uid, String journalId) async {
    final pageSnapshots = await _firestore
        .collection('users')
        .doc(uid)
        .collection('journals')
        .doc(journalId)
        .collection('pages')
        .get();

    for (final doc in pageSnapshots.docs) {
      final data = doc.data();
      final page = Page(
        id: data['id'],
        journalId: data['journalId'],
        pageIndex: data['pageIndex'],
        backgroundStyle: data['backgroundStyle'],
        thumbnailAssetId: data['thumbnailAssetId'],
        inkData: data['inkData'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

      await _pageDao.insertPage(page);

      // 3. Sync Blocks for this Page
      // Note: We changed schema in FirestoreService to hierarchy?
      // Yes: journals/{jid}/pages/{pid}/blocks/{bid} was NOT implemented in service,
      // instead we did users/{uid}/blocks (Wait, checking previous edit...)

      // Reviewing FirestoreService edit:
      // "await _firestore.collection('users').doc(uid).collection('blocks').doc(block.id).set(_blockToMap(block));"
      // So blocks are TOP LEVEL.

      // This means we should Query blocks by pageId
      await _syncBlocksForPage(uid, page.id);
    }
  }

  Future<void> _syncBlocksForPage(String uid, String pageId) async {
    final blockSnapshots = await _firestore
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .where('pageId', isEqualTo: pageId)
        .get();

    for (final doc in blockSnapshots.docs) {
      final data = doc.data();

      // Parse payload
      String payloadJson = data['payloadJson'];

      // Download media if needed!
      if (data['type'] == 'image' || data['type'] == 'audio') {
        payloadJson = await _ensureMediaDownloaded(data['type'], payloadJson);
      }

      final block = Block(
        id: data['id'],
        pageId: data['pageId'],
        type: BlockType.values.byName(data['type']),
        x: (data['x'] as num).toDouble(),
        y: (data['y'] as num).toDouble(),
        width: (data['width'] as num).toDouble(),
        height: (data['height'] as num).toDouble(),
        rotation: (data['rotation'] as num).toDouble(),
        zIndex: data['zIndex'],
        payloadJson: payloadJson,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

      await _blockDao.insertBlock(block);
    }
  }

  Future<String> _ensureMediaDownloaded(String type, String payloadJson) async {
    try {
      if (type == 'image') {
        final payload = ImageBlockPayload.fromJson(jsonDecode(payloadJson));
        if (payload.storagePath != null &&
            (payload.path == null || !File(payload.path!).existsSync())) {
          // Download
          final url = await _storageService.getDownloadUrl(
            payload.storagePath!,
          );
          if (url != null) {
            // We need to download file bytes and save locally
            // This basic logic assumes cached_network_image or we download to Documents
            // For robustness, let's download to a local file.
            final localFile = await _downloadFile(url, payload.storagePath!);

            // Update payload with new local path
            return ImageBlockPayload(
              assetId: payload.assetId,
              path: localFile.path,
              originalWidth: payload.originalWidth,
              originalHeight: payload.originalHeight,
              caption: payload.caption,
              frameStyle: payload.frameStyle,
              storagePath: payload.storagePath,
            ).toJsonString();
          }
        }
      } else if (type == 'audio') {
        final payload = AudioBlockPayload.fromJson(jsonDecode(payloadJson));
        if (payload.storagePath != null &&
            (payload.path == null || !File(payload.path!).existsSync())) {
          final url = await _storageService.getDownloadUrl(
            payload.storagePath!,
          );
          if (url != null) {
            final localFile = await _downloadFile(url, payload.storagePath!);
            return AudioBlockPayload(
              assetId: payload.assetId,
              path: localFile.path,
              durationMs: payload.durationMs,
              storagePath: payload.storagePath,
            ).toJsonString();
          }
        }
      }
    } catch (e) {
      debugPrint('Media Sync Error: $e');
    }
    return payloadJson;
  }

  Future<File> _downloadFile(String url, String storagePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = storagePath.split('/').last;
    final savePath = '${docsDir.path}/$fileName';
    final file = File(savePath);

    // Simple download using HttpClient
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    await response.pipe(file.openWrite());

    return file;
  }
}
