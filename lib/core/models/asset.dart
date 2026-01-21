import 'package:uuid/uuid.dart';
import 'base_entity.dart';

/// Asset kind enum
enum AssetKind { image, audio, ink, thumbnail }

/// Asset entity - represents a media file associated with a block
class Asset implements BaseEntity {
  @override
  final String id;

  final String ownerBlockId;
  final AssetKind kind;
  final String? localPath;
  final String? remoteUrl;
  final String? metaJson;
  final String? checksum;
  final int? sizeBytes;

  @override
  final int schemaVersion;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? deletedAt;

  Asset({
    String? id,
    required this.ownerBlockId,
    required this.kind,
    this.localPath,
    this.remoteUrl,
    this.metaJson,
    this.checksum,
    this.sizeBytes,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  bool get hasLocalFile => localPath != null;
  bool get hasRemoteFile => remoteUrl != null;

  Asset copyWith({
    String? id,
    String? ownerBlockId,
    AssetKind? kind,
    String? localPath,
    String? remoteUrl,
    String? metaJson,
    String? checksum,
    int? sizeBytes,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      ownerBlockId: ownerBlockId ?? this.ownerBlockId,
      kind: kind ?? this.kind,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      metaJson: metaJson ?? this.metaJson,
      checksum: checksum ?? this.checksum,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Asset(id: $id, kind: $kind, blockId: $ownerBlockId)';
}
