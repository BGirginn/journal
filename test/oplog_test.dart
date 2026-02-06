import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/sync/hlc.dart';

void main() {
  group('OplogEntry', () {
    test('create factory works', () {
      final hlc = Hlc.now('device1');
      final entry = OplogEntry.create(
        journalId: 'j1',
        pageId: 'p1',
        blockId: 'b1',
        opType: OplogType.create,
        hlc: hlc,
        deviceId: 'device1',
        userId: 'u1',
        payloadJson: '{"foo":"bar"}',
      );

      expect(entry.opId, '${hlc.toString()}-device1');
      expect(entry.status, OplogStatus.pending);
      expect(entry.payloadJson, '{"foo":"bar"}');
    });

    test('toMap works', () {
      const hlc = Hlc(1000, 1, 'd1');
      final entry = OplogEntry(
        opId: 'op1',
        journalId: 'j1',
        opType: OplogType.update,
        hlc: hlc,
        deviceId: 'd1',
        userId: 'u1',
        payloadJson: '{}',
        status: OplogStatus.sent,
        createdAt: DateTime(2023),
      );

      final map = entry.toMap();
      expect(map['opId'], 'op1');
      expect(map['hlc'], '1000:0001:d1');
      expect(map['status'], 'sent');
    });
  });
}
