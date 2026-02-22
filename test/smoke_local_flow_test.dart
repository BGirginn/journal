import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/database/app_database.dart';
import 'package:journal_app/core/models/block.dart' as block_model;
import 'package:journal_app/core/models/journal.dart' as journal_model;
import 'package:journal_app/core/models/page.dart' as page_model;

void main() {
  group('Local smoke flows', () {
    test('journal create smoke', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final journal = journal_model.Journal(
        title: 'Smoke Journal',
        ownerId: 'user-1',
      );
      await db.journalDao.insertJournal(journal);
      await db.pageDao.insertPage(
        page_model.Page(journalId: journal.id, pageIndex: 0),
      );

      final loadedJournal = await db.journalDao.getById(journal.id);
      final pages = await db.pageDao.getPagesForJournal(journal.id);

      expect(loadedJournal, isNotNull);
      expect(pages.length, 1);
      expect(pages.first.pageIndex, 0);
    });

    test('save and reload smoke', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'journal_v2_smoke_',
      );
      final dbFile = File('${tempDir.path}/journal_test.sqlite');

      final db1 = AppDatabase(NativeDatabase(dbFile));
      final journal = journal_model.Journal(
        title: 'Persisted Journal',
        ownerId: 'user-2',
      );
      await db1.journalDao.insertJournal(journal);
      await db1.pageDao.insertPage(
        page_model.Page(journalId: journal.id, pageIndex: 0),
      );
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(dbFile));
      addTearDown(() async {
        await db2.close();
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final loadedJournal = await db2.journalDao.getById(journal.id);
      final pages = await db2.pageDao.getPagesForJournal(journal.id);

      expect(loadedJournal, isNotNull);
      expect(loadedJournal?.title, 'Persisted Journal');
      expect(pages.length, 1);
    });

    test('block create and delete smoke', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final journal = journal_model.Journal(
        title: 'Editor Smoke',
        ownerId: 'user-3',
      );
      await db.journalDao.insertJournal(journal);
      final page = page_model.Page(journalId: journal.id, pageIndex: 0);
      await db.pageDao.insertPage(page);

      final block = block_model.Block(
        pageId: page.id,
        type: block_model.BlockType.text,
        x: 0.1,
        y: 0.2,
        width: 0.6,
        height: 0.2,
        payloadJson: '{"content":"hello"}',
      );
      await db.blockDao.insertBlock(block);
      await db.blockDao.softDelete(block.id);

      final blocks = await db.blockDao.getBlocksForPage(page.id);
      expect(blocks, isEmpty);
    });
  });
}
