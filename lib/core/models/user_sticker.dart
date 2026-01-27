import 'package:journal_app/core/models/base_entity.dart';
import 'package:uuid/uuid.dart';

enum StickerType {
  image,
  emoji,
  drawing;

  String get name => toString().split('.').last;
}

class UserSticker implements BaseEntity {
  @override
  final String id;

  final String userId;
  final StickerType type;
  final String content; // imageUrl, emoji char, or local path
  final String? localPath; // For cached images/drawings
  final String category; // 'favorites', 'custom', etc.

  @override
  final int schemaVersion;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;

  UserSticker({
    String? id,
    required this.userId,
    required this.type,
    required this.content,
    this.localPath,
    this.category = 'custom',
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  factory UserSticker.fromJson(Map<String, dynamic> json) {
    return UserSticker(
      id: json['id'],
      userId: json['userId'],
      type: StickerType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'],
      localPath: json['localPath'],
      category: json['category'] ?? 'custom',
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
      'userId': userId,
      'type': type.name,
      'content': content,
      'localPath': localPath,
      'category': category,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
