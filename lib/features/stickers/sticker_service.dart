import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/core/database/daos/sticker_dao.dart';
import 'package:journal_app/core/models/user_sticker.dart';

final stickerServiceProvider = Provider<StickerService>((ref) {
  final stickerDao = ref.watch(databaseProvider).stickerDao;
  final authService = ref.read(authServiceProvider);
  return StickerService(stickerDao, authService);
});

class StickerService {
  final StickerDao _stickerDao;
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _syncSubscription;

  StickerService(this._stickerDao, this._authService) {
    _initSync();
  }

  void _initSync() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _syncSubscription?.cancel();
    _syncSubscription = _firestore
        .collection('user_stickers')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added ||
                doc.type == DocumentChangeType.modified) {
              final sticker = UserSticker.fromJson(doc.doc.data()!);
              await _stickerDao.insertSticker(sticker);
            } else if (doc.type == DocumentChangeType.removed) {
              await _stickerDao.deleteSticker(doc.doc.id);
            }
          }
        });
  }

  Stream<List<UserSticker>> watchMyStickers() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _stickerDao.watchMyStickers(uid);
  }

  Future<UserSticker> createSticker({
    required StickerType type,
    required String content,
    String? localPath,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final sticker = UserSticker(
      userId: uid,
      type: type,
      content: content,
      localPath: localPath,
    );

    // 1. Local Save
    await _stickerDao.insertSticker(sticker);

    // 2. Remote Save
    await _firestore
        .collection('user_stickers')
        .doc(sticker.id)
        .set(sticker.toJson());

    return sticker;
  }

  Future<void> deleteSticker(String id) async {
    // 1. Local
    await _stickerDao.deleteSticker(id);

    // 2. Remote (Soft delete or hard?)
    // Soft delete usually update 'deletedAt' but Firestore handling of deletes...
    // Let's just update deletedAt
    await _firestore.collection('user_stickers').doc(id).update({
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }
}
