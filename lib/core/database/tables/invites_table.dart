import 'package:drift/drift.dart';

class Invites extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // team, journal
  TextColumn get targetId => text()(); // teamId or journalId
  TextColumn get inviterId => text()();
  TextColumn get inviteeId => text().nullable()();
  TextColumn get status => text()(); // pending, accepted, rejected
  TextColumn get role => text()(); // owner, editor, viewer
  DateTimeColumn get expiresAt => dateTime()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
