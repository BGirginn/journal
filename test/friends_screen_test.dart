import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/features/friends/friends_screen.dart';

void main() {
  testWidgets('FriendsView renders Ekle/İstekler/Arkadaşlar tabs', (
    tester,
  ) async {
    final profile = UserProfile(
      uid: 'u1',
      displayName: 'Test User',
      firstName: 'Test',
      lastName: 'User',
      username: 'test_user',
      friends: const [],
      receivedFriendRequests: const [],
      sentFriendRequests: const [],
      isProfileComplete: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAvailableProvider.overrideWith((ref) => true),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          myProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: const MaterialApp(home: Scaffold(body: FriendsView())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ekle'), findsOneWidget);
    expect(find.text('İstekler'), findsOneWidget);
    expect(find.text('Arkadaşlar'), findsOneWidget);

    await tester.tap(find.text('İstekler'));
    await tester.pumpAndSettle();
    expect(find.text('Bekleyen istek yok.'), findsOneWidget);

    await tester.tap(find.text('Arkadaşlar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Henüz arkadaşın yok. Ekle sekmesinden kullanıcı adı ile arama yapabilirsin.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('edge swipe on last friends tab requests root profile tab', (
    tester,
  ) async {
    final profile = UserProfile(
      uid: 'u1',
      displayName: 'Test User',
      firstName: 'Test',
      lastName: 'User',
      username: 'test_user',
      friends: const [],
      receivedFriendRequests: const [],
      sentFriendRequests: const [],
      isProfileComplete: true,
    );
    int? requestedRootTab;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAvailableProvider.overrideWith((ref) => true),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          myProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FriendsView(
              onEdgeSwipeToRootTab: (rootTabIndex) {
                requestedRootTab = rootTabIndex;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Arkadaşlar'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TabBarView), const Offset(-700, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(requestedRootTab, 4);
  });

  testWidgets('search result card remains stable while sending request', (
    tester,
  ) async {
    const me = 'user_me';
    const other = 'user_other';

    final firestore = FakeFirebaseFirestore();
    await firestore.collection(FirestorePaths.users).doc(me).set({
      'uid': me,
      'displayName': 'Ben',
      'username': 'ben',
      'friends': const <String>[],
      'receivedFriendRequests': const <String>[],
      'sentFriendRequests': const <String>[],
      'isProfileComplete': true,
    });
    await firestore.collection(FirestorePaths.users).doc(other).set({
      'uid': other,
      'displayName': 'CokUzunTestKullaniciAdi Deneme',
      'username': 'uzun_test_kullanici',
      'friends': const <String>[],
      'receivedFriendRequests': const <String>[],
      'sentFriendRequests': const <String>[],
      'isProfileComplete': true,
    });
    await firestore.collection(FirestorePaths.usernames).doc('hedef').set({
      'uid': other,
    });

    final service = UserService(
      AuthService(isFirebaseAvailable: false),
      isAvailable: true,
      firestore: firestore,
      currentUidProvider: () => me,
    );

    final profileController = StreamController<UserProfile?>();
    addTearDown(profileController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAvailableProvider.overrideWith((ref) => true),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          userServiceProvider.overrideWithValue(service),
          myProfileProvider.overrideWith((ref) => profileController.stream),
        ],
        child: const MaterialApp(home: Scaffold(body: FriendsView())),
      ),
    );

    profileController.add(
      UserProfile(
        uid: me,
        displayName: 'Ben',
        username: 'ben',
        friends: const <String>[],
        receivedFriendRequests: const <String>[],
        sentFriendRequests: const <String>[],
        isProfileComplete: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hedef');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.textContaining('CokUzunTestKullaniciAdi'), findsOneWidget);
    expect(find.byIcon(Icons.person_add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_add));
    profileController.add(
      UserProfile(
        uid: me,
        displayName: 'Ben',
        username: 'ben',
        friends: const <String>[],
        receivedFriendRequests: const <String>[],
        sentFriendRequests: const <String>[other],
        isProfileComplete: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('İptal Et'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
