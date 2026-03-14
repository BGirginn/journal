import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/features/notifications/models/app_notification.dart';
import 'package:journal_app/features/notifications/notifications_repository.dart';
import 'package:journal_app/features/notifications/notifications_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUser extends Mock implements User {}

class _SpyNotificationService extends NotificationService {
  _SpyNotificationService({required super.prefs})
    : super(firestore: FakeFirebaseFirestore(), isFirebaseAvailable: false);

  final List<String> marked = <String>[];

  @override
  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  }) async {
    marked.add('$uid/$notificationId');
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('shows action buttons for invite_received notifications', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 'n1',
      type: AppNotificationType.inviteReceived,
      title: 'Yeni davet',
      body: 'Takıma davet edildiniz',
      inviteId: 'inv_1',
      inviteType: 'team',
      targetId: 'team_1',
      actorId: 'u1',
      isRead: false,
      createdAt: DateTime(2026, 2, 1, 12, 0),
      readAt: null,
      route: '/notifications',
      schemaVersion: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPendingInvitesProvider.overrideWith((ref) => Stream.value([])),
          myNotificationsProvider.overrideWith(
            (ref) => Stream.value([notification]),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yeni davet'), findsOneWidget);
    expect(find.text('Kabul Et'), findsOneWidget);
    expect(find.text('Reddet'), findsOneWidget);
  });

  testWidgets('shows pending invite fallback when inbox doc is missing', (
    tester,
  ) async {
    final pendingInvite = Invite(
      id: 'inv_pending_1',
      type: InviteType.journal,
      targetId: 'journal_1',
      inviterId: 'owner_1',
      inviteeId: 'user_1',
      role: JournalRole.editor,
      expiresAt: DateTime(2026, 3, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myNotificationsProvider.overrideWith((ref) => Stream.value([])),
          myPendingInvitesProvider.overrideWith(
            (ref) => Stream.value([pendingInvite]),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yeni günlük daveti'), findsOneWidget);
    expect(find.text('Kabul Et'), findsOneWidget);
    expect(find.text('Reddet'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it as read', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 'n2',
      type: AppNotificationType.inviteAccepted,
      title: 'Davet kabul edildi',
      body: 'Davetiniz kabul edildi',
      inviteId: 'inv_2',
      inviteType: 'team',
      targetId: 'team_2',
      actorId: 'u2',
      isRead: false,
      createdAt: DateTime(2026, 2, 1, 12, 0),
      readAt: null,
      route: '/notifications',
      schemaVersion: 1,
    );

    final user = _MockUser();
    when(() => user.uid).thenReturn('user_1');

    final spyService = _SpyNotificationService(prefs: prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAvailableProvider.overrideWith((ref) => false),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          notificationServiceProvider.overrideWithValue(spyService),
          myPendingInvitesProvider.overrideWith((ref) => Stream.value([])),
          myNotificationsProvider.overrideWith(
            (ref) => Stream.value([notification]),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Davet kabul edildi'));
    await tester.pumpAndSettle();

    expect(spyService.marked, contains('user_1/n2'));
  });
}
