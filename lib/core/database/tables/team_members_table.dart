import 'package:drift/drift.dart';

class TeamMembers extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()(); // 'owner', 'editor', 'viewer'
  DateTimeColumn get joinedAt => dateTime()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
