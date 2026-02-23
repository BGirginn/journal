import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
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
}
