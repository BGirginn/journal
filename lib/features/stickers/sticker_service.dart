import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/sticker_dao.dart';
import 'package:journal_app/core/models/user_sticker.dart';

final stickerServiceProvider = Provider<StickerService>((ref) {
  final stickerDao = ref.watch(databaseProvider).stickerDao;
  final authService = ref.read(authServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  final telemetry = ref.watch(telemetryServiceProvider);
  final service = StickerService(stickerDao, authService, logger, telemetry);
  ref.listen(authStateProvider, (_, next) {
    service.onAuthStateChanged(next.value?.uid);
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});

class StickerService {
  final StickerDao _stickerDao;
  final AuthService _authService;
  final AppLogger _logger;
  final TelemetryService _telemetry;
  final FirebaseFirestore _firestore;
  final String? Function()? _currentUidProvider;

  StreamSubscription? _syncSubscription;
  String? _activeUid;

  StickerService(
    this._stickerDao,
    this._authService,
    this._logger,
    this._telemetry, {
    FirebaseFirestore? firestore,
    String? Function()? currentUidProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUidProvider = currentUidProvider;

  String? get _currentUid =>
      _currentUidProvider?.call() ?? _authService.currentUser?.uid;

  void _reportStickerIssue({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typed = SyncError(
      code: 'sticker_$operation',
      message: 'Sticker service operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    _logger.warn(
      'sticker_service_issue',
      data: {'operation': operation, ...extra},
      error: typed,
      stackTrace: stackTrace,
    );
    _telemetry.track(
      'sticker_service_issue',
      params: {'operation': operation, 'error_code': typed.code, ...extra},
    );
  }

  void onAuthStateChanged(String? uid) {
    if (_activeUid == uid) return;
    _activeUid = uid;
    _stopSync();
    if (uid == null) return;
    _syncSubscription?.cancel();
    _syncSubscription = _firestore
        .collection(FirestorePaths.userStickers)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) async {
            for (var doc in snapshot.docChanges) {
              if (doc.type == DocumentChangeType.added ||
                  doc.type == DocumentChangeType.modified) {
                final sticker = UserSticker.fromJson(doc.doc.data()!);
                await _stickerDao.insertSticker(sticker);
              } else if (doc.type == DocumentChangeType.removed) {
                await _stickerDao.deleteSticker(doc.doc.id);
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _reportStickerIssue(
              operation: 'listen_stickers',
              error: error,
              stackTrace: stackTrace,
              extra: {'uid': uid},
            );
          },
        );
  }

  void _stopSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }

  Stream<List<UserSticker>> watchMyStickers() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);
    return _stickerDao.watchMyStickers(uid);
  }

  Future<UserSticker> createSticker({
    required StickerType type,
    required String content,
    String? localPath,
    String category = 'custom',
    bool bestEffortRemote = true,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not logged in');
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      throw Exception('Sticker içeriği boş olamaz');
    }
    final normalizedCategory = category.trim().isEmpty
        ? 'custom'
        : category.trim().toLowerCase();

    final sticker = UserSticker(
      userId: uid,
      type: type,
      content: normalizedContent,
      localPath: localPath,
      category: normalizedCategory,
    );

    // 1. Local Save
    await _stickerDao.insertSticker(sticker);

    // 2. Remote Save
    try {
      await _firestore
          .collection(FirestorePaths.userStickers)
          .doc(sticker.id)
          .set(sticker.toJson());
    } catch (error, stackTrace) {
      _reportStickerIssue(
        operation: 'create_remote',
        error: error,
        stackTrace: stackTrace,
        extra: {'uid': uid, 'sticker_id': sticker.id, 'type': type.name},
      );
      if (!bestEffortRemote) rethrow;
    }

    return sticker;
  }

  Future<void> deleteSticker(String id) async {
    // 1. Local
    await _stickerDao.deleteSticker(id);

    // 2. Remote (Soft delete or hard?)
    // Soft delete usually update 'deletedAt' but Firestore handling of deletes...
    // Let's just update deletedAt
    await _firestore.collection(FirestorePaths.userStickers).doc(id).update({
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  void dispose() {
    _stopSync();
  }
}
