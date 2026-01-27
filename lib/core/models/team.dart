import 'package:uuid/uuid.dart';
import 'base_entity.dart';

enum JournalRole {
  owner,
  editor,
  viewer;

  String get displayName {
    switch (this) {
      case JournalRole.owner:
        return 'Sahip';
      case JournalRole.editor:
        return 'Düzenleyici';
      case JournalRole.viewer:
        return 'Görüntüleyici';
    }
  }
}

class Team implements BaseEntity {
  @override
  final String id;

  final String name;
  final String ownerId;
  final String? description;
  final String? avatarUrl;

  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;

  Team({
    String? id,
    required this.name,
    required this.ownerId,
    this.description,
    this.avatarUrl,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  Team copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? description,
    String? avatarUrl,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'description': description,
      'avatarUrl': avatarUrl,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      ownerId: json['ownerId'],
      description: json['description'],
      avatarUrl: json['avatarUrl'],
      schemaVersion: json['schemaVersion'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }
}
