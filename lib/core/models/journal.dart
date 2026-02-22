import 'package:uuid/uuid.dart';
import 'base_entity.dart';

/// Journal entity - represents a notebook/diary
class Journal implements BaseEntity {
  @override
  final String id;

  final String title;
  final String coverStyle;
  final String? coverImageUrl;
  final String? teamId;
  final String? ownerId;

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
    this.coverImageUrl,
    this.teamId,
    this.ownerId,
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
    String? coverImageUrl,
    String? teamId,
    String? ownerId,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      coverStyle: coverStyle ?? this.coverStyle,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      teamId: teamId ?? this.teamId,
      ownerId: ownerId ?? this.ownerId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Journal(id: $id, title: $title, teamId: $teamId)';
}
