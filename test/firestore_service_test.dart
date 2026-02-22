import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/database/firestore_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const uid = 'u1';

  late FakeFirebaseFirestore firestore;
  late SharedPreferences prefs;
  late List<OplogEntry> oplogs;
  late FirestoreService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    firestore = FakeFirebaseFirestore();
    oplogs = [];

    service = FirestoreService(
      AuthService(isFirebaseAvailable: false),
      (entry) async => oplogs.add(entry),
      prefs,
      firestore: firestore,
      currentUidProvider: () => uid,
    );
  });

  test('create/update/delete journal writes firestore and oplog', () async {
    final journal = Journal(id: 'j1', title: 'My Journal', coverStyle: 'plain');

    await service.createJournal(journal);

    final createdDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journal.id)
        .get();

    expect(createdDoc.exists, isTrue);
    expect(createdDoc.data()!['title'], equals('My Journal'));
    expect(oplogs.last.opType, equals(OplogType.create));

    final updated = journal.copyWith(title: 'Updated');
    await service.updateJournal(updated);

    final updatedDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journal.id)
        .get();

    expect(updatedDoc.data()!['title'], equals('Updated'));
    expect(oplogs.last.opType, equals(OplogType.update));

    await service.deleteJournal(journal.id);

    final deletedDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.journals)
        .doc(journal.id)
        .get();

    expect(deletedDoc.exists, isFalse);
    expect(oplogs.last.opType, equals(OplogType.delete));
  });

  test(
    'create and update page writes nested page path and oplog envelope',
    () async {
      final page = Page(id: 'p1', journalId: 'j1', pageIndex: 0);

      await service.createPage(page);

      final createdDoc = await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc('j1')
          .collection(FirestorePaths.pages)
          .doc('p1')
          .get();

      expect(createdDoc.exists, isTrue);
      expect(createdDoc.data()!['pageIndex'], equals(0));

      final firstPayload =
          jsonDecode(oplogs.first.payloadJson) as Map<String, dynamic>;
      expect(firstPayload['entity'], equals('page'));
      expect(firstPayload['operation'], equals('create'));

      await service.updatePage(page.copyWith(pageIndex: 3));

      final updatedDoc = await firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.journals)
          .doc('j1')
          .collection(FirestorePaths.pages)
          .doc('p1')
          .get();

      expect(updatedDoc.data()!['pageIndex'], equals(3));
      expect(oplogs.last.opType, equals(OplogType.update));
    },
  );

  test('create/update/delete block uses top-level blocks path', () async {
    final block = Block(
      id: 'b1',
      pageId: 'p1',
      type: BlockType.text,
      x: 0.1,
      y: 0.2,
      width: 0.3,
      height: 0.4,
      payloadJson: jsonEncode({'content': 'hello'}),
    );

    await service.createBlock(block, journalId: 'j1');

    final createdDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(block.id)
        .get();

    expect(createdDoc.exists, isTrue);
    expect(createdDoc.data()!['pageId'], equals('p1'));

    final updatedBlock = block.copyWith(x: 0.9, y: 0.8);
    await service.updateBlock(updatedBlock, journalId: 'j1');

    final updatedDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(block.id)
        .get();

    expect(updatedDoc.data()!['x'], equals(0.9));
    expect(updatedDoc.data()!['y'], equals(0.8));

    await service.deleteBlock(block.id, journalId: 'j1', pageId: 'p1');

    final deletedDoc = await firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.blocks)
        .doc(block.id)
        .get();

    expect(deletedDoc.exists, isFalse);
    expect(oplogs.length, equals(3));
    expect(oplogs.map((e) => e.opType), everyElement(isA<OplogType>()));
  });

  test(
    'generated oplogs contain stable device id and increasing hlc',
    () async {
      final journal = Journal(id: 'j_hlc', title: 'HLC', coverStyle: 'plain');

      await service.createJournal(journal);
      await service.updateJournal(journal.copyWith(title: 'HLC 2'));

      expect(oplogs.length, equals(2));
      expect(oplogs[0].deviceId, isNotEmpty);
      expect(oplogs[0].deviceId, equals(oplogs[1].deviceId));
      expect(
        oplogs[0].hlc.toString().compareTo(oplogs[1].hlc.toString()) < 0,
        isTrue,
      );

      final persistedDeviceId = prefs.getString('sync_device_id');
      final persistedHlc = prefs.getString('sync_last_hlc');

      expect(persistedDeviceId, equals(oplogs[0].deviceId));
      expect(persistedHlc, equals(oplogs[1].hlc.toString()));
    },
  );

  test('throws auth error when uid is unavailable', () async {
    final unauthenticated = FirestoreService(
      AuthService(isFirebaseAvailable: false),
      (_) async {},
      prefs,
      firestore: firestore,
      currentUidProvider: () => null,
    );

    final journal = Journal(id: 'j-auth', title: 'Denied', coverStyle: 'plain');

    expect(
      () => unauthenticated.createJournal(journal),
      throwsA(isA<AuthError>()),
    );
  });
}
