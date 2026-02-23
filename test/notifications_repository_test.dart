import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/features/notifications/notifications_repository.dart';

void main() {
  const uid = 'user_1';

  test(
    'watchNotifications returns notifications sorted by createdAt desc',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = NotificationsRepository(firestore: firestore);

      final collection = firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.notifications);

      await collection.doc('n_old').set({
        'id': 'n_old',
        'type': 'invite_received',
        'title': 'Old',
        'body': 'Old body',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'route': '/notifications',
        'schemaVersion': 1,
      });
      await collection.doc('n_new').set({
        'id': 'n_new',
        'type': 'invite_received',
        'title': 'New',
        'body': 'New body',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'route': '/notifications',
        'schemaVersion': 1,
      });

      final notifications = await repo.watchNotifications(uid).first;
      expect(notifications.map((n) => n.id).toList(), ['n_new', 'n_old']);
    },
  );

  test('watchUnreadCount counts only unread docs', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = NotificationsRepository(firestore: firestore);

    final collection = firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.notifications);

    await collection.doc('n1').set({
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
    await collection.doc('n2').set({
      'isRead': true,
      'createdAt': Timestamp.now(),
    });
    await collection.doc('n3').set({
      'isRead': false,
      'createdAt': Timestamp.now(),
    });

    final unreadCount = await repo.watchUnreadCount(uid).first;
    expect(unreadCount, 2);
  });
}
