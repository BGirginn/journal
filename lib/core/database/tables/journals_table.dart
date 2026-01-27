import 'package:drift/drift.dart';

/// Journals table - stores notebook metadata
class Journals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get coverStyle => text().withDefault(const Constant('default'))();
  TextColumn get teamId => text().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
