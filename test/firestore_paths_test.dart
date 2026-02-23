import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/database/firestore_paths.dart';

void main() {
  test('builds user and nested document paths', () {
    const uid = 'u1';
    const journalId = 'j1';
    const pageId = 'p1';
    const blockId = 'b1';
    const deviceId = 'd1';
    const notificationId = 'n1';

    expect(FirestorePaths.userDoc(uid), equals('users/u1'));
    expect(
      FirestorePaths.journalDoc(uid, journalId),
      equals('users/u1/journals/j1'),
    );
    expect(
      FirestorePaths.pageDoc(uid, journalId, pageId),
      equals('users/u1/journals/j1/pages/p1'),
    );
    expect(FirestorePaths.blockDoc(uid, blockId), equals('users/u1/blocks/b1'));
    expect(
      FirestorePaths.userPushTokenDoc(uid, deviceId),
      equals('users/u1/push_tokens/d1'),
    );
    expect(
      FirestorePaths.userNotificationDoc(uid, notificationId),
      equals('users/u1/notifications/n1'),
    );
  });
}
