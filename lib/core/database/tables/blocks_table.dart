import 'package:drift/drift.dart';

/// Blocks table - stores block content on pages
/// Coordinates are normalized [0..1]
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get type => text()(); // text, image, handwriting
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();
  IntColumn get zIndex => integer().withDefault(const Constant(0))();
  TextColumn get state => text().withDefault(const Constant('normal'))();
  TextColumn get payloadJson => text()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
