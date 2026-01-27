import 'package:uuid/uuid.dart';
import 'base_entity.dart';
import 'team.dart';

class TeamMember implements BaseEntity {
  @override
  final String id;

  final String teamId;
  final String userId;
  final JournalRole role;
  final DateTime joinedAt;

  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;

  TeamMember({
    String? id,
    required this.teamId,
    required this.userId,
    required this.role,
    DateTime? joinedAt,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       joinedAt = joinedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  TeamMember copyWith({
    String? id,
    String? teamId,
    String? userId,
    JournalRole? role,
    DateTime? joinedAt,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      teamId: json['teamId'],
      userId: json['userId'],
      role: JournalRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => JournalRole.viewer,
      ),
      joinedAt: DateTime.parse(json['joinedAt']),
      schemaVersion: json['schemaVersion'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }
}
