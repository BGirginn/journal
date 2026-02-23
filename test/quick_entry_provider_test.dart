import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/app_database.dart' show AppDatabase;
import 'package:journal_app/core/database/firestore_service.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'quick entry creates journal, first page and first text block',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final firestoreService = FirestoreService(
        AuthService(isFirebaseAvailable: false),
        (_) async {},
        prefs,
        firestore: FakeFirebaseFirestore(),
        currentUidProvider: () => null,
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AuthService(isFirebaseAvailable: false),
          ),
          firestoreServiceProvider.overrideWithValue(firestoreService),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final createQuickEntry = container.read(createQuickJournalEntryProvider);
      final journalId = await createQuickEntry('Bugün çok iyi geçti.');

      final journal = await db.journalDao.getById(journalId);
      expect(journal, isNotNull);
      expect(journal!.title, isNotEmpty);

      final pages = await db.pageDao.getPagesForJournal(journal.id);
      expect(pages, hasLength(1));

      final blocks = await db.blockDao.getBlocksForPage(pages.first.id);
      expect(blocks, hasLength(1));
      expect(blocks.first.type, BlockType.text);

      final payload = TextBlockPayload.fromJson(blocks.first.payload);
      expect(payload.content, 'Bugün çok iyi geçti.');
    },
  );

  test('quick entry throws for empty text input', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final firestoreService = FirestoreService(
      AuthService(isFirebaseAvailable: false),
      (_) async {},
      prefs,
      firestore: FakeFirebaseFirestore(),
      currentUidProvider: () => null,
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(
          AuthService(isFirebaseAvailable: false),
        ),
        firestoreServiceProvider.overrideWithValue(firestoreService),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final createQuickEntry = container.read(createQuickJournalEntryProvider);
    await expectLater(() => createQuickEntry('   '), throwsArgumentError);
  });
}
