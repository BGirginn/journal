import 'package:drift/drift.dart';

class UserStickers extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // image, emoji, drawing
  TextColumn get content => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('custom'))();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
