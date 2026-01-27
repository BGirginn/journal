import 'package:journal_app/core/models/base_entity.dart';
import 'package:journal_app/core/models/team.dart';
export 'package:journal_app/core/models/team.dart' show JournalRole;
import 'package:uuid/uuid.dart';

enum InviteType {
  team,
  journal;

  String get name => toString().split('.').last;
}

enum InviteStatus {
  pending,
  accepted,
  rejected,
  expired;

  String get name => toString().split('.').last;
}

class Invite implements BaseEntity {
  @override
  final String id;

  final InviteType type;
  final String targetId;
  final String inviterId;
  final String? inviteeId;
  final InviteStatus status;
  final JournalRole role;
  final DateTime expiresAt;

  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;

  Invite({
    String? id,
    required this.type,
    required this.targetId,
    required this.inviterId,
    this.inviteeId,
    this.status = InviteStatus.pending,
    required this.role,
    required this.expiresAt,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'],
      type: InviteType.values.firstWhere((e) => e.name == json['type']),
      targetId: json['targetId'],
      inviterId: json['inviterId'],
      inviteeId: json['inviteeId'],
      status: InviteStatus.values.firstWhere((e) => e.name == json['status']),
      role: JournalRole.values.firstWhere((e) => e.name == json['role']),
      expiresAt: DateTime.parse(json['expiresAt']),
      schemaVersion: json['schemaVersion'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'targetId': targetId,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'status': status.name,
      'role': role.name,
      'expiresAt': expiresAt.toIso8601String(),
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
