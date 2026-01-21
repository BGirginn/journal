import 'package:uuid/uuid.dart';
import 'base_entity.dart';

/// Journal entity - represents a notebook/diary
class Journal implements BaseEntity {
  @override
  final String id;

  final String title;
  final String coverStyle;

  @override
  final int schemaVersion;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? deletedAt;

  Journal({
    String? id,
    required this.title,
    this.coverStyle = 'default',
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  Journal copyWith({
    String? id,
    String? title,
    String? coverStyle,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      coverStyle: coverStyle ?? this.coverStyle,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Journal(id: $id, title: $title)';
}
