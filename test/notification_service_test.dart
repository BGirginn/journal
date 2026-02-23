import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sync_device_id': 'device_test',
      'app_locale_code': 'en',
    });
    prefs = await SharedPreferences.getInstance();
    firestore = FakeFirebaseFirestore();
  });

  test(
    'registerOrUpdatePushToken writes token under users/{uid}/push_tokens/{deviceId}',
    () async {
      final messaging = _MockFirebaseMessaging();
      final auth = _MockFirebaseAuth();
      final user = _MockUser();

      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('user_1');
      when(() => messaging.getToken()).thenAnswer((_) async => 'token_123');

      await firestore.collection(FirestorePaths.users).doc('user_1').set({
        'uid': 'user_1',
      });

      final service = NotificationService(
        prefs: prefs,
        messaging: messaging,
        firestore: firestore,
        auth: auth,
        isFirebaseAvailable: true,
      );

      await service.registerOrUpdatePushToken();

      final tokenDoc = await firestore
          .collection(FirestorePaths.users)
          .doc('user_1')
          .collection(FirestorePaths.pushTokens)
          .doc('device_test')
          .get();

      expect(tokenDoc.exists, isTrue);
      expect(tokenDoc.data()!['token'], equals('token_123'));
      expect(tokenDoc.data()!['preferredLanguage'], equals('en'));

      final legacyDoc = await firestore
          .collection(FirestorePaths.users)
          .doc('user_1')
          .get();
      expect(legacyDoc.data()!['fcmToken'], equals('token_123'));
    },
  );

  test('markNotificationRead updates isRead and readAt', () async {
    await firestore
        .collection(FirestorePaths.users)
        .doc('user_1')
        .collection(FirestorePaths.notifications)
        .doc('notif_1')
        .set({'isRead': false, 'readAt': null});

    final service = NotificationService(
      prefs: prefs,
      firestore: firestore,
      isFirebaseAvailable: false,
    );

    await service.markNotificationRead(
      uid: 'user_1',
      notificationId: 'notif_1',
    );

    final doc = await firestore
        .collection(FirestorePaths.users)
        .doc('user_1')
        .collection(FirestorePaths.notifications)
        .doc('notif_1')
        .get();

    expect(doc.data()!['isRead'], isTrue);
    expect(doc.data()!['readAt'], isNotNull);
  });
}
