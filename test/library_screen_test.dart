import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/services/deep_link_service.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/features/library/library_screen.dart';
import 'package:journal_app/features/notifications/notifications_repository.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _NoopDeepLinkService extends DeepLinkService {
  _NoopDeepLinkService(super.ref);

  @override
  Future<void> init(BuildContext context) async {}

  @override
  void dispose() {}
}

class _StubNotificationService extends NotificationService {
  _StubNotificationService({required super.prefs})
    : super(firestore: FakeFirebaseFirestore(), isFirebaseAvailable: false);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderScope buildScope({
    required Widget child,
    List<Override> extraOverrides = const [],
  }) {
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

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseAvailableProvider.overrideWith((ref) => false),
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        journalsProvider.overrideWith((ref) => Stream.value(const [])),
        totalPageCountProvider.overrideWith((ref) async => 0),
        myProfileProvider.overrideWith((ref) => Stream.value(profile)),
        unreadNotificationCountProvider.overrideWith((ref) => Stream.value(0)),
        myNotificationsProvider.overrideWith((ref) => Stream.value(const [])),
        deepLinkServiceProvider.overrideWith(
          (ref) => _NoopDeepLinkService(ref),
        ),
        notificationServiceProvider.overrideWithValue(
          _StubNotificationService(prefs: prefs),
        ),
        ...extraOverrides,
      ],
      child: child,
    );
  }

  testWidgets(
    'home tab shows global app bar with inbox and keeps bottom navigation',
    (tester) async {
      await tester.pumpWidget(
        buildScope(
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
      expect(find.text('Anasayfa'), findsWidgets);
    },
  );

  testWidgets('profile is reachable from bottom navigation', (tester) async {
    await tester.pumpWidget(
      buildScope(
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LibraryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.user));
    await tester.pumpAndSettle();

    expect(find.text('Profil ve Ayarlar'), findsWidgets);
  });

  testWidgets('create dialog passes selected coverStyle to createJournal', (
    tester,
  ) async {
    String? capturedTitle;
    String? capturedCoverStyle;

    await tester.pumpWidget(
      buildScope(
        extraOverrides: [
          createJournalProvider.overrideWith((ref) {
            return ({
              required String title,
              String coverStyle = 'default',
              String? teamId,
            }) async {
              capturedTitle = title;
              capturedCoverStyle = coverStyle;
              throw Exception('skip_navigation_for_test');
            };
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LibraryScreen(initialTab: 0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LibraryScreen)),
    )!;
    await tester.enterText(find.byType(TextField), 'Yeni Test Günlüğü');

    await tester.tap(find.textContaining('Tema:'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Özel Kağıt 1').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.libraryCreateAction).last);
    await tester.pumpAndSettle();

    expect(capturedTitle, 'Yeni Test Günlüğü');
    expect(capturedCoverStyle, 'paper_img_1');
  });
}
