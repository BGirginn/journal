import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';

Future<void> _waitUntil(Future<bool> Function() check) async {
  for (var i = 0; i < 30; i++) {
    if (await check()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Condition was not met in time');
}

void main() {
  test('createSticker writes local and remote', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'sticker_user_1';
    final service = StickerService(
      db.stickerDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final sticker = await service.createSticker(
      type: StickerType.emoji,
      content: '🙂',
    );

    final local = await db.stickerDao.watchMyStickers(uid).first;
    expect(local.map((e) => e.id), contains(sticker.id));

    final doc = await firestore
        .collection(FirestorePaths.userStickers)
        .doc(sticker.id)
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['content'], equals('🙂'));
  });

  test('onAuthStateChanged syncs remote stickers to local', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'sticker_sync_1';
    final service = StickerService(
      db.stickerDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final remoteSticker = UserSticker(
      userId: uid,
      type: StickerType.drawing,
      content: 'draw_01',
      localPath: '/tmp/draw_01.png',
    );
    await firestore
        .collection(FirestorePaths.userStickers)
        .doc(remoteSticker.id)
        .set(remoteSticker.toJson());

    service.onAuthStateChanged(uid);

    await _waitUntil(() async {
      final stickers = await db.stickerDao.watchMyStickers(uid).first;
      return stickers.any((s) => s.id == remoteSticker.id);
    });
  });

  test('deleteSticker soft deletes local and marks remote deletedAt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    var uid = 'sticker_delete_1';
    final service = StickerService(
      db.stickerDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final created = await service.createSticker(
      type: StickerType.image,
      content: 'path/to/image.png',
    );
    await service.deleteSticker(created.id);

    final visibleStickers = await db.stickerDao.watchMyStickers(uid).first;
    expect(visibleStickers.any((s) => s.id == created.id), isFalse);

    final remoteDoc = await firestore
        .collection(FirestorePaths.userStickers)
        .doc(created.id)
        .get();
    expect(remoteDoc.exists, isTrue);
    expect(remoteDoc.data()!['deletedAt'], isNotNull);
  });
}
