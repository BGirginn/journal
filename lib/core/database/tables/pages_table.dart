import 'package:drift/drift.dart';

/// Pages table - stores page metadata within a journal
class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get journalId => text()();
  IntColumn get pageIndex => integer()();
  TextColumn get backgroundStyle =>
      text().withDefault(const Constant('plain_white'))();
  TextColumn get thumbnailAssetId => text().nullable()();
  TextColumn get inkData =>
      text().withDefault(const Constant(''))(); // JSON encoded strokes
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
