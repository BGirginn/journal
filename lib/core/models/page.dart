import 'package:uuid/uuid.dart';
import 'base_entity.dart';

/// Page entity - represents a page in a journal
class Page implements BaseEntity {
  @override
  final String id;

  final String journalId;
  final int pageIndex;
  final String backgroundStyle;
  final String? thumbnailAssetId;
  final String inkData; // JSON encoded ink strokes
  final String tags; // Comma-separated tags

  /// Get tags as list
  List<String> get tagList =>
      tags.isEmpty ? [] : tags.split(',').map((t) => t.trim()).toList();

  @override
  final int schemaVersion;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? deletedAt;

  Page({
    String? id,
    required this.journalId,
    required this.pageIndex,
    this.backgroundStyle = 'plain_white',
    this.thumbnailAssetId,
    this.inkData = '',
    this.tags = '',
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  Page copyWith({
    String? id,
    String? journalId,
    int? pageIndex,
    String? backgroundStyle,
    String? thumbnailAssetId,
    String? inkData,
    String? tags,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Page(
      id: id ?? this.id,
      journalId: journalId ?? this.journalId,
      pageIndex: pageIndex ?? this.pageIndex,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      thumbnailAssetId: thumbnailAssetId ?? this.thumbnailAssetId,
      inkData: inkData ?? this.inkData,
      tags: tags ?? this.tags,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() =>
      'Page(id: $id, journalId: $journalId, index: $pageIndex)';
}
