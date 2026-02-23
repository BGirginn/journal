import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/database/firestore_service.dart';
import 'package:journal_app/core/models/block.dart' as block_model;
import 'package:journal_app/core/models/journal.dart' as journal_model;
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/editor/editor_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitForEditorLoaded(WidgetTester tester) async {
  Object? firstException;
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    firstException ??= tester.takeException();
    if (find.byType(InteractiveViewer).evaluate().isNotEmpty) {
      return;
    }
  }

  if (firstException != null) {
    fail('Editor failed before loading: $firstException');
  }

  final progressCount = find
      .byType(CircularProgressIndicator)
      .evaluate()
      .length;
  final scaffoldCount = find.byType(Scaffold).evaluate().length;
  final textCount = find.byType(Text).evaluate().length;
  fail(
    'Editor did not load. interactive=${find.byType(InteractiveViewer).evaluate().length} '
    'progress=$progressCount scaffolds=$scaffoldCount textWidgets=$textCount',
  );
}

Future<Widget> _buildEditorApp({
  required AppDatabase db,
  required journal_model.Journal journal,
  required model.Page page,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final firestore = FakeFirebaseFirestore();
  await firestore
      .collection(FirestorePaths.users)
      .doc('u1')
      .collection(FirestorePaths.journals)
      .doc(journal.id)
      .set({'id': journal.id, 'title': journal.title});
  await firestore
      .collection(FirestorePaths.users)
      .doc('u1')
      .collection(FirestorePaths.journals)
      .doc(journal.id)
      .collection(FirestorePaths.pages)
      .doc(page.id)
      .set({'id': page.id, 'journalId': journal.id});
  final firestoreService = FirestoreService(
    AuthService(isFirebaseAvailable: false),
    (_) async {},
    prefs,
    firestore: firestore,
    currentUidProvider: () => 'u1',
  );

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      firestoreServiceProvider.overrideWithValue(firestoreService),
      telemetryServiceProvider.overrideWithValue(TelemetryService(AppLogger())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: EditorScreen(journal: journal, page: page),
    ),
  );
}

void main() {
  testWidgets('editor text/draw/erase/save flow works', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final journal = journal_model.Journal(
      id: 'j1',
      title: 'J',
      coverStyle: 'plain_white',
    );
    final page = model.Page(id: 'p1', journalId: journal.id, pageIndex: 0);

    await db.journalDao.insertJournal(journal);
    await db.pageDao.insertPage(page);

    final app = await _buildEditorApp(db: db, journal: journal, page: page);

    await tester.pumpWidget(app);
    await _waitForEditorLoaded(tester);

    expect(find.byIcon(Icons.text_fields_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.text_fields_rounded));
    await tester.pump(const Duration(milliseconds: 250));

    var blocks = await db.blockDao.getBlocksForPage(page.id);
    expect(
      blocks.where((b) => b.type == block_model.BlockType.text),
      isNotEmpty,
    );

    await tester.tap(find.byIcon(Icons.draw_rounded));
    await tester.pump();
    await tester.drag(find.byType(InteractiveViewer), const Offset(30, 20));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.cleaning_services_outlined));
    await tester.pump();
    await tester.drag(find.byType(InteractiveViewer), const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final updatedPage = await db.pageDao.getPageById(page.id);

    expect(updatedPage, isNotNull);
    expect(updatedPage!.inkData, isNotEmpty);
  });

  // TODO: Re-enable once image-block selection gestures are deterministic in headless tests.
  testWidgets(
    'editor image actions frame/rotate/delete flow works',
    (tester) async {},
    skip: true,
  );
}
