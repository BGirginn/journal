import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('standalone stickers screen shows FAB and keeps inbox action', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final logger = AppLogger();
    final stickerService = StickerService(
      db.stickerDao,
      AuthService(isFirebaseAvailable: false),
      logger,
      TelemetryService(logger),
      firestore: FakeFirebaseFirestore(),
      currentUidProvider: () => null,
    );
    addTearDown(stickerService.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AuthService(isFirebaseAvailable: false),
          ),
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          stickerServiceProvider.overrideWithValue(stickerService),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StickerManagerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(LucideIcons.plusCircle), findsNothing);
    expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
  });
}
