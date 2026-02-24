import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pages_table.dart';
import '../../models/page.dart' as model;

part 'page_dao.g.dart';

@DriftAccessor(tables: [Pages])
class PageDao extends DatabaseAccessor<AppDatabase> with _$PageDaoMixin {
  PageDao(super.db);

  /// Watch all non-deleted pages for a journal, ordered by page index
  Stream<List<model.Page>> watchPagesForJournal(String journalId) {
    return (select(pages)
          ..where((t) => t.journalId.equals(journalId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Get all non-deleted pages for a journal, ordered by page index
  Future<List<model.Page>> getPagesForJournal(String journalId) async {
    final rows =
        await (select(pages)
              ..where(
                (t) => t.journalId.equals(journalId) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
            .get();
    return rows.map(_rowToModel).toList();
  }

  /// Get a single page by ID
  Future<model.Page?> getPageById(String id) async {
    final query = select(pages)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get a single non-deleted page by journal and page index
  Future<model.Page?> getPageByJournalAndIndex(
    String journalId,
    int pageIndex,
  ) async {
    final query = select(pages)
      ..where(
        (t) =>
            t.journalId.equals(journalId) &
            t.pageIndex.equals(pageIndex) &
            t.deletedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get the maximum page index for a journal
  Future<int> getMaxPageIndex(String journalId) async {
    final query = selectOnly(pages)
      ..addColumns([pages.pageIndex.max()])
      ..where(pages.journalId.equals(journalId) & pages.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(pages.pageIndex.max()) ?? -1;
  }

  /// Insert a new page
  Future<void> insertPage(model.Page page) async {
    await into(
      pages,
    ).insert(_modelToCompanion(page), mode: InsertMode.insertOrReplace);
  }

  /// Update an existing page
  Future<void> updatePage(model.Page page) async {
    await (update(pages)..where((t) => t.id.equals(page.id))).write(
      _modelToCompanion(page.copyWith(updatedAt: DateTime.now())),
    );
  }

  /// Soft delete a page
  Future<void> softDelete(String id) async {
    await (update(pages)..where((t) => t.id.equals(id))).write(
      PagesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update ink data for a page
  Future<void> updateInkData(String pageId, String inkJson) async {
    await (update(pages)..where((t) => t.id.equals(pageId))).write(
      PagesCompanion(inkData: Value(inkJson), updatedAt: Value(DateTime.now())),
    );
  }

  /// Get page count for a journal
  Future<int> getPageCount(String journalId) async {
    final query = selectOnly(pages)
      ..addColumns([pages.id.count()])
      ..where(pages.journalId.equals(journalId) & pages.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(pages.id.count()) ?? 0;
  }

  model.Page _rowToModel(Page row) {
    return model.Page(
      id: row.id,
      journalId: row.journalId,
      pageIndex: row.pageIndex,
      backgroundStyle: row.backgroundStyle,
      thumbnailAssetId: row.thumbnailAssetId,
      inkData: row.inkData,
      schemaVersion: row.schemaVersion,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  PagesCompanion _modelToCompanion(model.Page page) {
    return PagesCompanion(
      id: Value(page.id),
      journalId: Value(page.journalId),
      pageIndex: Value(page.pageIndex),
      backgroundStyle: Value(page.backgroundStyle),
      thumbnailAssetId: Value(page.thumbnailAssetId),
      inkData: Value(page.inkData),
      schemaVersion: Value(page.schemaVersion),
      createdAt: Value(page.createdAt),
      updatedAt: Value(page.updatedAt),
      deletedAt: Value(page.deletedAt),
    );
  }
}
