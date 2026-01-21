import 'package:drift/drift.dart';

/// Assets table - stores media file references
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get ownerBlockId => text()();
  TextColumn get kind => text()(); // image, audio, ink, thumbnail
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get metaJson => text().nullable()();
  TextColumn get checksum => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
