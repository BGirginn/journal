import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tables.dart';
import 'daos/daos.dart';

part 'app_database.g.dart';

/// Main database class for the journal app
@DriftDatabase(
  tables: [
    Journals,
    Pages,
    Blocks,
    Assets,
    Teams,
    TeamMembers,
    Invites,
    UserStickers,
    Oplogs,
  ],
  daos: [
    JournalDao,
    PageDao,
    BlockDao,
    AssetDao,
    TeamDao,
    InviteDao,
    StickerDao,
    OplogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(pages, pages.inkData);
        }
        if (from < 3) {
          await m.addColumn(journals, journals.ownerId);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'journal_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
