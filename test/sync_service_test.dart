import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/core/sync/hlc.dart';
import 'package:journal_app/core/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStorageGateway implements StorageGateway {
  @override
  Future<void> deleteFile(String storagePath) async {}

  @override
  Future<String?> getDownloadUrl(String storagePath) async => null;

  @override
  Future<String?> uploadFile(File file, {String? customPath}) async => null;
}

OplogEntry _makeOplog({
  required String opId,
  required String uid,
  required String hlc,
  required OplogType opType,
  required String payloadJson,
  required String journalId,
  String? pageId,
  String? blockId,
}) {
  return OplogEntry(
    opId: opId,
    journalId: journalId,
    pageId: pageId,
    blockId: blockId,
    opType: opType,
    hlc: Hlc.parse(hlc),
    deviceId: 'device_test',
    userId: uid,
    payloadJson: payloadJson,
    status: OplogStatus.pending,
    createdAt: DateTime.now(),
  );
}

void main() {
  test('syncUp uploads pending oplog and reconcile applies journal', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    const uid = 'sync_user_1';

    final service = SyncService(
      AuthService(isFirebaseAvailable: false),
      _FakeStorageGateway(),
      db.journalDao,
      db.pageDao,
      db.blockDao,
      db.oplogDao,
      prefs,
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final now = DateTime.now().toUtc();
    final payload = jsonEncode({
      'schemaVersion': 1,
      'entity': 'journal',
      'operation': 'create',
      'data': {
        'id': 'journal_sync_1',
        'title': 'From Oplog',
        'coverStyle': 'paper_img_1',
        'schemaVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    });
    final entry = _makeOplog(
      opId: 'op_sync_up_1',
      uid: uid,
      hlc: Hlc.now('device_test').toString(),
      opType: OplogType.create,
      payloadJson: payload,
      journalId: 'journal_sync_1',
    );
    await db.oplogDao.insertOplog(entry);

    await service.syncUp();

    final localOplog = await db.oplogDao.getById(entry.opId);
    final localJournal = await db.journalDao.getById('journal_sync_1');
    final remoteDoc = await firestore
        .collection(FirestorePaths.oplogs)
        .doc(entry.opId)
        .get();

    expect(localOplog, isNotNull);
    expect(localOplog!.status, OplogStatus.applied);
    expect(localJournal, isNotNull);
    expect(remoteDoc.exists, isTrue);
  });

  test('reconcile handles invalid oplog and applies delete ops', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final logger = AppLogger();
    final telemetry = TelemetryService(logger);
    const uid = 'sync_user_2';

    final service = SyncService(
      AuthService(isFirebaseAvailable: false),
      _FakeStorageGateway(),
      db.journalDao,
      db.pageDao,
      db.blockDao,
      db.oplogDao,
      prefs,
      logger,
      telemetry,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
    addTearDown(() async {
      service.dispose();
      await db.close();
    });

    final journal = Journal(id: 'journal_del_1', title: 'Delete Me');
    final page = Page(id: 'page_del_1', journalId: journal.id, pageIndex: 0);
    final block = Block(
      id: 'block_del_1',
      pageId: page.id,
      type: BlockType.text,
      x: 0.1,
      y: 0.1,
      width: 0.2,
      height: 0.2,
      payloadJson: jsonEncode({'content': 'x'}),
    );
    await db.journalDao.insertJournal(journal);
    await db.pageDao.insertPage(page);
    await db.blockDao.insertBlock(block);

    final h1 = Hlc.now('remote_dev_1');
    final h2 = h1.send(DateTime.now().millisecondsSinceEpoch + 1);
    final h3 = h2.send(DateTime.now().millisecondsSinceEpoch + 2);
    final h4 = h3.send(DateTime.now().millisecondsSinceEpoch + 3);

    await firestore.collection(FirestorePaths.oplogs).doc('bad_op').set({
      'opId': 'bad_op',
      'journalId': 'journal_del_1',
      'opType': 'unknown',
      'hlc': h1.toString(),
      'deviceId': 'remote_dev_1',
      'userId': uid,
      'payloadJson': '{}',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });

    final deleteJournal = _makeOplog(
      opId: 'delete_journal_1',
      uid: uid,
      hlc: h2.toString(),
      opType: OplogType.delete,
      payloadJson: jsonEncode({
        'schemaVersion': 1,
        'entity': 'journal',
        'operation': 'delete',
        'data': {'id': journal.id},
      }),
      journalId: journal.id,
    );
    final deletePage = _makeOplog(
      opId: 'delete_page_1',
      uid: uid,
      hlc: h3.toString(),
      opType: OplogType.delete,
      payloadJson: jsonEncode({
        'schemaVersion': 1,
        'entity': 'page',
        'operation': 'delete',
        'data': {'id': page.id, 'journalId': journal.id},
      }),
      journalId: journal.id,
      pageId: page.id,
    );
    final deleteBlock = _makeOplog(
      opId: 'delete_block_1',
      uid: uid,
      hlc: h4.toString(),
      opType: OplogType.delete,
      payloadJson: jsonEncode({
        'schemaVersion': 1,
        'entity': 'block',
        'operation': 'delete',
        'data': {'id': block.id, 'pageId': page.id},
      }),
      journalId: journal.id,
      pageId: page.id,
      blockId: block.id,
    );

    await firestore
        .collection(FirestorePaths.oplogs)
        .doc(deleteJournal.opId)
        .set(deleteJournal.toMap());
    await firestore
        .collection(FirestorePaths.oplogs)
        .doc(deletePage.opId)
        .set(deletePage.toMap());
    await firestore
        .collection(FirestorePaths.oplogs)
        .doc(deleteBlock.opId)
        .set(deleteBlock.toMap());

    await service.reconcile();

    expect(await db.journalDao.getById(journal.id), isNull);
    expect(await db.pageDao.getPageById(page.id), isNull);
    expect(await db.blockDao.getById(block.id), isNull);
    expect(
      (await db.oplogDao.getById(deleteJournal.opId))?.status,
      OplogStatus.applied,
    );
    expect(
      (await db.oplogDao.getById(deletePage.opId))?.status,
      OplogStatus.applied,
    );
    expect(
      (await db.oplogDao.getById(deleteBlock.opId))?.status,
      OplogStatus.applied,
    );
  });

  test(
    'bootstrapDown runs once and syncs legacy journals/pages/blocks',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final logger = AppLogger();
      final telemetry = TelemetryService(logger);
      const uid = 'sync_user_boot_1';

      final service = SyncService(
        AuthService(isFirebaseAvailable: false),
        _FakeStorageGateway(),
        db.journalDao,
        db.pageDao,
        db.blockDao,
        db.oplogDao,
        prefs,
        logger,
        telemetry,
        firestore: firestore,
        currentUidProvider: () => uid,
      );
      addTearDown(() async {
        service.dispose();
        await db.close();
      });

      final createdAt = Timestamp.fromDate(DateTime.now().toUtc());
      final updatedAt = Timestamp.fromDate(DateTime.now().toUtc());

      await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc('legacy_journal_1')
          .set({
            'id': 'legacy_journal_1',
            'title': 'Legacy',
            'coverStyle': 'paper_img_2',
            'createdAt': createdAt,
            'updatedAt': updatedAt,
            'deletedAt': null,
          });
      await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc('legacy_journal_1')
          .collection(FirestorePaths.pages)
          .doc('legacy_page_1')
          .set({
            'id': 'legacy_page_1',
            'journalId': 'legacy_journal_1',
            'pageIndex': 0,
            'backgroundStyle': 'plain_white',
            'thumbnailAssetId': null,
            'inkData': '',
            'createdAt': createdAt,
            'updatedAt': updatedAt,
          });
      await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.blocks)
          .doc('legacy_block_1')
          .set({
            'id': 'legacy_block_1',
            'pageId': 'legacy_page_1',
            'type': 'text',
            'x': 0.1,
            'y': 0.1,
            'width': 0.3,
            'height': 0.2,
            'rotation': 0.0,
            'zIndex': 1,
            'payloadJson': jsonEncode({'content': 'legacy'}),
            'createdAt': createdAt,
            'updatedAt': updatedAt,
          });

      await service.bootstrapDown();

      expect(await db.journalDao.getById('legacy_journal_1'), isNotNull);
      expect(await db.pageDao.getPageById('legacy_page_1'), isNotNull);
      expect(await db.blockDao.getById('legacy_block_1'), isNotNull);

      await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc('legacy_journal_2')
          .set({
            'id': 'legacy_journal_2',
            'title': 'Should Not Hydrate',
            'coverStyle': 'paper_img_3',
            'createdAt': createdAt,
            'updatedAt': updatedAt,
            'deletedAt': null,
          });

      await service.bootstrapDown();

      expect(await db.journalDao.getById('legacy_journal_2'), isNull);
    },
  );
}
