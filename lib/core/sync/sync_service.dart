import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/daos/block_dao.dart';
import 'package:journal_app/core/database/daos/journal_dao.dart';
import 'package:journal_app/core/database/daos/oplog_dao.dart';
import 'package:journal_app/core/database/daos/page_dao.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/sync/hlc.dart';
import 'package:journal_app/core/sync/sync_engine.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:journal_app/providers/database_providers.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  final journalDao = ref.watch(journalDaoProvider);
  final pageDao = ref.watch(pageDaoProvider);
  final blockDao = ref.watch(blockDaoProvider);
  final oplogDao = ref.watch(oplogDaoProvider);
  final logger = ref.watch(appLoggerProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final syncService = SyncService(
    authService,
    storageService,
    journalDao,
    pageDao,
    blockDao,
    oplogDao,
    prefs,
    logger,
    telemetry,
  );
  ref.onDispose(syncService.dispose);
  return syncService;
});

final pendingOplogCountProvider = StreamProvider<int>((ref) {
  final oplogDao = ref.watch(oplogDaoProvider);
  return oplogDao.watchPendingCount();
});

final pendingOplogEntriesProvider = StreamProvider<List<OplogEntry>>((ref) {
  final oplogDao = ref.watch(oplogDaoProvider);
  return oplogDao.watchPendingEntries(limit: 100);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return ref.watch(syncServiceProvider);
});

final syncUploaderProvider = Provider<SyncUploader>((ref) {
  return ref.watch(syncServiceProvider);
});

final syncReconcilerProvider = Provider<SyncReconciler>((ref) {
  return ref.watch(syncServiceProvider);
});

final syncBootstrapperProvider = Provider<SyncBootstrapper>((ref) {
  return ref.watch(syncServiceProvider);
});

class SyncService implements SyncEngine {
  final AuthService _authService;
  final StorageGateway _storageService;
  final JournalDao _journalDao;
  final PageDao _pageDao;
  final BlockDao _blockDao;
  // Reserved for Phase 4 HLC sync
  // ignore: unused_field
  final OplogDao _oplogDao;
  final SharedPreferences _prefs;
  final AppLogger _logger;
  final TelemetryService _telemetry;
  final FirebaseFirestore _firestore;
  final String? Function()? _currentUidProvider;
  Timer? _uploaderTimer;

  SyncService(
    this._authService,
    this._storageService,
    this._journalDao,
    this._pageDao,
    this._blockDao,
    this._oplogDao,
    this._prefs,
    this._logger,
    this._telemetry, {
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUidProvider = currentUidProvider;

  static const _bootstrapDoneKeyPrefix = 'sync_bootstrap_done_';
  static const _reconcileWatermarkKeyPrefix = 'sync_reconcile_hlc_';

  String _bootstrapDoneKey(String uid) => '$_bootstrapDoneKeyPrefix$uid';
  String _reconcileWatermarkKey(String uid) =>
      '$_reconcileWatermarkKeyPrefix$uid';

  String? get _userId =>
      _currentUidProvider?.call() ?? _authService.currentUser?.uid;

  void _reportSyncIssue({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typed = SyncError(
      code: 'sync_$operation',
      message: 'Sync operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    _logger.warn(
      'sync_issue',
      data: {'operation': operation, ...extra},
      error: typed,
      stackTrace: stackTrace,
    );
    _telemetry.track(
      'sync_issue',
      params: {'operation': operation, 'error_code': typed.code, ...extra},
    );
  }

  Future<void> syncDown() => bootstrapDown();

  @override
  Future<void> bootstrapDown() async {
    final uid = _userId;
    if (uid == null) return;

    final alreadyBootstrapped = _prefs.getBool(_bootstrapDoneKey(uid)) ?? false;
    if (alreadyBootstrapped) return;

    await _legacySyncDown();
    await _prefs.setBool(_bootstrapDoneKey(uid), true);
  }

  @override
  Future<void> startSyncLoop() async {
    _uploaderTimer?.cancel();
    _uploaderTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await syncUp();
    });
    await syncUp();
  }

  @override
  void stopSyncLoop() {
    _uploaderTimer?.cancel();
    _uploaderTimer = null;
  }

  void dispose() {
    stopSyncLoop();
  }

  @override
  Future<void> syncUp() async {
    final uid = _userId;
    if (uid == null) return;
    final startedAt = DateTime.now();

    final pending = await _oplogDao.getPendingOplogs();
    var acked = 0;
    var failed = 0;
    for (final entry in pending) {
      await _oplogDao.updateOplogStatus(entry.opId, OplogStatus.sent);
      try {
        await _retryWithBackoff(() async {
          await _firestore
              .collection(FirestorePaths.oplogs)
              .doc(entry.opId)
              .set({
                ...entry.toMap(),
                'status': OplogStatus.sent.name,
                'ackedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        });
        await _oplogDao.updateOplogStatus(entry.opId, OplogStatus.acked);
        acked += 1;
      } catch (e, st) {
        _reportSyncIssue(
          operation: 'upload_oplog',
          error: e,
          stackTrace: st,
          extra: {'op_id': entry.opId},
        );
        await _oplogDao.updateOplogStatus(entry.opId, OplogStatus.failed);
        failed += 1;
      }
    }

    final pendingAfter = await _oplogDao.getPendingOplogs();
    _telemetry.track(
      'sync_latency',
      params: {
        'duration_ms': DateTime.now().difference(startedAt).inMilliseconds,
        'pending_before': pending.length,
        'acked': acked,
        'failed': failed,
        'pending_after': pendingAfter.length,
      },
    );
    _telemetry.track('pending_queue', params: {'count': pendingAfter.length});

    await reconcile();
  }

  @override
  Future<void> reconcile() async {
    final uid = _userId;
    if (uid == null) return;
    final watermarkRaw = _prefs.getString(_reconcileWatermarkKey(uid));
    final watermark = Hlc.tryParse(watermarkRaw);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection(FirestorePaths.oplogs)
          .where('userId', isEqualTo: uid)
          .orderBy('hlc')
          .limit(300)
          .get();
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'reconcile_ordered_query',
        error: e,
        stackTrace: st,
      );
      snapshot = await _firestore
          .collection(FirestorePaths.oplogs)
          .where('userId', isEqualTo: uid)
          .limit(300)
          .get();
    }

    var appliedCount = 0;
    Hlc? latestAppliedHlc = watermark;
    for (final doc in snapshot.docs) {
      final remoteEntry = _entryFromRemote(doc.data());
      if (remoteEntry == null) continue;
      if (watermark != null && remoteEntry.hlc <= watermark) continue;

      final existing = await _oplogDao.getById(remoteEntry.opId);
      if (existing?.status == OplogStatus.applied) {
        continue;
      }

      final applied = await _applyRemoteEntry(remoteEntry);
      if (!applied) {
        continue;
      }

      await _oplogDao.insertOplog(
        remoteEntry.copyWith(status: OplogStatus.applied),
      );
      appliedCount += 1;
      if (latestAppliedHlc == null || remoteEntry.hlc > latestAppliedHlc) {
        latestAppliedHlc = remoteEntry.hlc;
      }
    }

    if (latestAppliedHlc != null) {
      await _prefs.setString(
        _reconcileWatermarkKey(uid),
        latestAppliedHlc.toString(),
      );
    }

    _telemetry.track(
      'reconcile_outcome',
      params: {'applied_count': appliedCount},
    );
  }

  Future<void> _retryWithBackoff(
    Future<void> Function() action, {
    int maxAttempts = 4,
    Duration initialDelay = const Duration(milliseconds: 300),
    Duration maxDelay = const Duration(seconds: 3),
  }) async {
    var attempt = 0;
    var delay = initialDelay;
    while (attempt < maxAttempts) {
      try {
        await action();
        return;
      } catch (e, st) {
        attempt += 1;
        _reportSyncIssue(
          operation: 'retry_attempt',
          error: e,
          stackTrace: st,
          extra: {'attempt': attempt},
        );
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(delay);
        final doubled = Duration(milliseconds: delay.inMilliseconds * 2);
        delay = doubled > maxDelay ? maxDelay : doubled;
      }
    }
  }

  OplogEntry? _entryFromRemote(Map<String, dynamic> data) {
    try {
      final opTypeRaw = (data['opType'] ?? OplogType.update.name).toString();
      final statusRaw = (data['status'] ?? OplogStatus.pending.name).toString();
      final createdAt = _parseDate(data['createdAt']) ?? DateTime.now();
      return OplogEntry(
        opId: data['opId'] as String,
        journalId: data['journalId'] as String,
        pageId: data['pageId'] as String?,
        blockId: data['blockId'] as String?,
        opType: OplogType.values.byName(opTypeRaw),
        hlc: Hlc.parse(data['hlc'] as String),
        deviceId: data['deviceId'] as String,
        userId: data['userId'] as String,
        payloadJson: data['payloadJson'] as String,
        status: OplogStatus.values.byName(statusRaw),
        createdAt: createdAt,
      );
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'parse_remote_oplog',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<bool> _applyRemoteEntry(OplogEntry entry) async {
    try {
      final envelope = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final entity = envelope['entity']?.toString();
      final operation = envelope['operation']?.toString() ?? entry.opType.name;
      final data = Map<String, dynamic>.from(
        (envelope['data'] as Map?) ?? const {},
      );

      switch (entity) {
        case 'journal':
          return _applyJournal(operation, data);
        case 'page':
          return _applyPage(operation, data);
        case 'block':
          return _applyBlock(operation, data);
        default:
          return false;
      }
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'apply_remote_entry',
        error: e,
        stackTrace: st,
        extra: {'op_id': entry.opId},
      );
      return false;
    }
  }

  Future<bool> _applyJournal(
    String operation,
    Map<String, dynamic> data,
  ) async {
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) return false;

    if (operation == OplogType.delete.name) {
      await _journalDao.softDelete(id);
      return true;
    }

    final incoming = Journal(
      id: id,
      title: data['title']?.toString() ?? '',
      coverStyle: data['coverStyle']?.toString() ?? 'default',
      teamId: data['teamId']?.toString(),
      ownerId: data['ownerId']?.toString(),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      deletedAt: _parseDate(data['deletedAt']),
    );

    final existing = await _journalDao.getById(id);
    if (existing != null && existing.updatedAt.isAfter(incoming.updatedAt)) {
      return true;
    }

    await _journalDao.insertJournal(incoming);
    return true;
  }

  Future<bool> _applyPage(String operation, Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    final journalId = data['journalId']?.toString();
    if (id == null || id.isEmpty || journalId == null || journalId.isEmpty) {
      return false;
    }

    if (operation == OplogType.delete.name) {
      await _pageDao.softDelete(id);
      return true;
    }

    final incoming = Page(
      id: id,
      journalId: journalId,
      pageIndex: (data['pageIndex'] as num?)?.toInt() ?? 0,
      backgroundStyle: data['backgroundStyle']?.toString() ?? 'plain_white',
      thumbnailAssetId: data['thumbnailAssetId']?.toString(),
      inkData: data['inkData']?.toString() ?? '',
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      deletedAt: _parseDate(data['deletedAt']),
    );

    final existing = await _pageDao.getPageById(id);
    if (existing != null && existing.updatedAt.isAfter(incoming.updatedAt)) {
      return true;
    }

    await _upsertPageWithIndexGuard(incoming);
    return true;
  }

  Future<bool> _applyBlock(String operation, Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    final pageId = data['pageId']?.toString();
    if (id == null || id.isEmpty || pageId == null || pageId.isEmpty) {
      return false;
    }

    if (operation == OplogType.delete.name) {
      await _blockDao.softDelete(id);
      return true;
    }

    final incoming = Block(
      id: id,
      pageId: pageId,
      type: BlockType.values.byName(data['type']?.toString() ?? 'text'),
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,
      width: (data['width'] as num?)?.toDouble() ?? 0.2,
      height: (data['height'] as num?)?.toDouble() ?? 0.2,
      rotation: (data['rotation'] as num?)?.toDouble() ?? 0,
      zIndex: (data['zIndex'] as num?)?.toInt() ?? 0,
      state: BlockState.values.byName(data['state']?.toString() ?? 'normal'),
      payloadJson: data['payloadJson']?.toString() ?? '{}',
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      deletedAt: _parseDate(data['deletedAt']),
    );

    final existing = await _blockDao.getById(id);
    if (existing != null && existing.updatedAt.isAfter(incoming.updatedAt)) {
      return true;
    }

    await _blockDao.insertBlock(incoming);
    return true;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _legacySyncDown() async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('Sync: No user logged in.');
      return;
    }

    try {
      _logger.info('sync_down_started');

      // 1. Sync Journals
      final journalSnapshots = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
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

      _logger.info('sync_down_completed');
    } catch (e, st) {
      _logger.error('sync_down_failed', error: e, stackTrace: st);
      _telemetry.track(
        'sync_issue',
        params: {
          'operation': 'legacy_sync_down',
          'error_code': 'sync_down_failed',
        },
      );
    }
  }

  Future<void> _syncPages(String uid, String journalId) async {
    final pageSnapshots = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journalId)
        .collection(FirestorePaths.pages)
        .get();

    final latestByIndex = <int, Page>{};
    for (final doc in pageSnapshots.docs) {
      final data = doc.data();
      final rawId = data['id']?.toString();
      final pageId = (rawId != null && rawId.isNotEmpty) ? rawId : doc.id;
      final page = Page(
        id: pageId,
        journalId: data['journalId']?.toString() ?? journalId,
        pageIndex: (data['pageIndex'] as num?)?.toInt() ?? 0,
        backgroundStyle: data['backgroundStyle']?.toString() ?? 'plain_white',
        thumbnailAssetId: data['thumbnailAssetId'],
        inkData: data['inkData']?.toString() ?? '',
        createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
        updatedAt:
            _parseDate(data['updatedAt']) ??
            _parseDate(data['createdAt']) ??
            DateTime.now(),
      );
      final current = latestByIndex[page.pageIndex];
      if (current == null || page.updatedAt.isAfter(current.updatedAt)) {
        latestByIndex[page.pageIndex] = page;
      }
    }

    final pages = latestByIndex.values.toList()
      ..sort((a, b) => a.pageIndex.compareTo(b.pageIndex));
    for (final page in pages) {
      await _upsertPageWithIndexGuard(page);
      await _syncBlocksForPage(uid, page.id);
    }
  }

  Future<void> _upsertPageWithIndexGuard(Page incoming) async {
    final existing = await _pageDao.getPageById(incoming.id);
    if (existing != null && existing.updatedAt.isAfter(incoming.updatedAt)) {
      return;
    }

    final sameIndex = await _pageDao.getPageByJournalAndIndex(
      incoming.journalId,
      incoming.pageIndex,
    );
    if (sameIndex != null && sameIndex.id != incoming.id) {
      if (sameIndex.updatedAt.isAfter(incoming.updatedAt)) {
        return;
      }
      await _pageDao.softDelete(sameIndex.id);
    }

    await _pageDao.insertPage(incoming);
  }

  Future<void> _syncBlocksForPage(String uid, String pageId) async {
    final blockSnapshots = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
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
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'media_download_prepare',
        error: e,
        stackTrace: st,
      );
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
