import 'package:drift/drift.dart';

class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();
  TextColumn get description => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
