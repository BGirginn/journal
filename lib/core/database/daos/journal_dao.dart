import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/journals_table.dart';
import '../../models/journal.dart' as model;

part 'journal_dao.g.dart';

@DriftAccessor(tables: [Journals])
class JournalDao extends DatabaseAccessor<AppDatabase> with _$JournalDaoMixin {
  JournalDao(super.db);

  /// Get all non-deleted journals ordered by update time
  Stream<List<model.Journal>> watchAllJournals() {
    return (select(journals)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Get a single journal by ID
  Future<model.Journal?> getById(String id) async {
    final query = select(journals)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Insert a new journal
  Future<void> insertJournal(model.Journal journal) async {
    await into(
      journals,
    ).insert(_modelToCompanion(journal), mode: InsertMode.insertOrReplace);
  }

  /// Update an existing journal
  Future<void> updateJournal(model.Journal journal) async {
    await (update(journals)..where((t) => t.id.equals(journal.id))).write(
      _modelToCompanion(journal.copyWith(updatedAt: DateTime.now())),
    );
  }

  /// Soft delete a journal
  Future<void> softDelete(String id) async {
    await (update(journals)..where((t) => t.id.equals(id))).write(
      JournalsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  model.Journal _rowToModel(Journal row) {
    return model.Journal(
      id: row.id,
      title: row.title,
      coverStyle: row.coverStyle,
      teamId: row.teamId,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  JournalsCompanion _modelToCompanion(model.Journal journal) {
    return JournalsCompanion(
      id: Value(journal.id),
      title: Value(journal.title),
      coverStyle: Value(journal.coverStyle),
      teamId: Value(journal.teamId),
      schemaVersion: Value(journal.schemaVersion),
      createdAt: Value(journal.createdAt),
      updatedAt: Value(journal.updatedAt),
      deletedAt: Value(journal.deletedAt),
    );
  }
}
