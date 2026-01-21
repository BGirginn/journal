/// Base entity interface for all database models
abstract class BaseEntity {
  String get id;
  int get schemaVersion;
  DateTime get createdAt;
  DateTime get updatedAt;
  DateTime? get deletedAt;

  bool get isDeleted => deletedAt != null;
}
