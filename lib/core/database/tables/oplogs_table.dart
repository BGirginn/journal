import 'package:drift/drift.dart';

class Oplogs extends Table {
  TextColumn get opId => text()();
  TextColumn get journalId => text()();
  TextColumn get pageId => text().nullable()();
  TextColumn get blockId => text().nullable()();
  TextColumn get opType => text()(); // enum OplogType
  TextColumn get hlc => text()(); // HLC string
  TextColumn get deviceId => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text()(); // enum OplogStatus
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {opId};
}
