import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/oplog.dart';

void main() {
  group('OplogStatusMachine', () {
    test('allows canonical forward transitions', () {
      expect(
        OplogStatusMachine.canTransition(OplogStatus.pending, OplogStatus.sent),
        isTrue,
      );
      expect(
        OplogStatusMachine.canTransition(OplogStatus.sent, OplogStatus.acked),
        isTrue,
      );
      expect(
        OplogStatusMachine.canTransition(
          OplogStatus.acked,
          OplogStatus.applied,
        ),
        isTrue,
      );
    });

    test('allows retry transitions from failed', () {
      expect(
        OplogStatusMachine.canTransition(
          OplogStatus.failed,
          OplogStatus.pending,
        ),
        isTrue,
      );
      expect(
        OplogStatusMachine.canTransition(OplogStatus.failed, OplogStatus.sent),
        isTrue,
      );
    });

    test('rejects illegal transitions', () {
      expect(
        OplogStatusMachine.canTransition(
          OplogStatus.pending,
          OplogStatus.acked,
        ),
        isFalse,
      );
      expect(
        OplogStatusMachine.canTransition(
          OplogStatus.applied,
          OplogStatus.pending,
        ),
        isFalse,
      );
    });
  });
}
