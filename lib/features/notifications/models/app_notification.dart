import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  inviteReceived,
  inviteAccepted,
  inviteRejected,
  unknown;

  static AppNotificationType fromRaw(String? raw) {
    switch (raw) {
      case 'invite_received':
        return AppNotificationType.inviteReceived;
      case 'invite_accepted':
        return AppNotificationType.inviteAccepted;
      case 'invite_rejected':
        return AppNotificationType.inviteRejected;
      default:
        return AppNotificationType.unknown;
    }
  }
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? inviteId;
  final String? inviteType;
  final String? targetId;
  final String? actorId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String route;
  final int schemaVersion;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.inviteId,
    required this.inviteType,
    required this.targetId,
    required this.actorId,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
    required this.route,
    required this.schemaVersion,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: map['id'] as String? ?? doc.id,
      type: AppNotificationType.fromRaw(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      inviteId: map['inviteId'] as String?,
      inviteType: map['inviteType'] as String?,
      targetId: map['targetId'] as String?,
      actorId: map['actorId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      readAt: _parseDateTime(map['readAt']),
      route: map['route'] as String? ?? '/notifications',
      schemaVersion: map['schemaVersion'] as int? ?? 1,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
