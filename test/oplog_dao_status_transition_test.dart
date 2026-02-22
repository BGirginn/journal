import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/database/app_database.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/sync/hlc.dart';

void main() {
  group('OplogDao status transitions', () {
    test('enforces pending -> sent -> acked -> applied', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final entry = OplogEntry.create(
        journalId: 'j-1',
        opType: OplogType.update,
        hlc: Hlc.now('device-1'),
        deviceId: 'device-1',
        userId: 'user-1',
        payloadJson: '{}',
      );

      await db.oplogDao.insertOplog(entry);
      await db.oplogDao.updateOplogStatus(entry.opId, OplogStatus.sent);
      await db.oplogDao.updateOplogStatus(entry.opId, OplogStatus.acked);
      await db.oplogDao.updateOplogStatus(entry.opId, OplogStatus.applied);

      final updated = await db.oplogDao.getById(entry.opId);
      expect(updated?.status, OplogStatus.applied);
    });

    test('rejects illegal pending -> acked transition', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final entry = OplogEntry.create(
        journalId: 'j-2',
        opType: OplogType.create,
        hlc: Hlc.now('device-2'),
        deviceId: 'device-2',
        userId: 'user-2',
        payloadJson: '{}',
      );
      await db.oplogDao.insertOplog(entry);

      expect(
        () => db.oplogDao.updateOplogStatus(entry.opId, OplogStatus.acked),
        throwsStateError,
      );
    });
  });
}
