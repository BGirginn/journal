import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'base_entity.dart';

/// Block types enum
enum BlockType { text, image, audio, video }

/// Block state enum
enum BlockState { normal, selected, editing, locked }

/// Block entity - represents a content block on a page
/// Coordinates are normalized [0..1] for cross-device compatibility
class Block implements BaseEntity {
  @override
  final String id;

  final String pageId;
  final BlockType type;

  /// Normalized x position [0..1]
  final double x;

  /// Normalized y position [0..1]
  final double y;

  /// Normalized width [0..1]
  final double width;

  /// Normalized height [0..1]
  final double height;

  /// Rotation in degrees
  final double rotation;

  /// Z-index for layering
  final int zIndex;

  /// Block state
  final BlockState state;

  /// JSON payload containing block-specific data
  final String payloadJson;

  @override
  final int schemaVersion;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? deletedAt;

  /// Cached decoded payload to avoid repeated JSON parsing
  Map<String, dynamic>? _cachedPayload;

  Block({
    String? id,
    required this.pageId,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.state = BlockState.normal,
    required this.payloadJson,
    this.schemaVersion = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  bool get isDeleted => deletedAt != null;

  /// Parse the payload JSON (cached after first access)
  Map<String, dynamic> get payload =>
      _cachedPayload ??= jsonDecode(payloadJson);

  Block copyWith({
    String? id,
    String? pageId,
    BlockType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    BlockState? state,
    String? payloadJson,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Block(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      state: state ?? this.state,
      payloadJson: payloadJson ?? this.payloadJson,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Block(id: $id, type: $type, pageId: $pageId)';
}

/// Text block payload
class TextBlockPayload {
  final String content;
  final double fontSize;
  final String color;
  final String fontFamily;
  final String? textAlign;

  TextBlockPayload({
    required this.content,
    this.fontSize = 16.0,
    this.color = '#000000',
    this.fontFamily = 'default',
    this.textAlign,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'fontSize': fontSize,
    'color': color,
    'fontFamily': fontFamily,
    if (textAlign != null) 'textAlign': textAlign,
  };

  factory TextBlockPayload.fromJson(Map<String, dynamic> json) {
    return TextBlockPayload(
      content: json['content'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: json['color'] as String? ?? '#000000',
      fontFamily: json['fontFamily'] as String? ?? 'default',
      textAlign: json['textAlign'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Image block payload
class ImageBlockPayload {
  final String? assetId;
  final String? path; // Direct file path
  final int? originalWidth;
  final int? originalHeight;
  final String? caption;
  final String frameStyle; // 'none', 'polaroid', 'tape', 'shadow'
  final String? storagePath; // Cloud Storage path (optional)

  ImageBlockPayload({
    this.assetId,
    this.path,
    this.originalWidth,
    this.originalHeight,
    this.caption,
    this.frameStyle = 'none',
    this.storagePath,
  });

  Map<String, dynamic> toJson() => {
    if (assetId != null) 'assetId': assetId,
    if (path != null) 'path': path,
    if (originalWidth != null) 'originalWidth': originalWidth,
    if (originalHeight != null) 'originalHeight': originalHeight,
    if (caption != null) 'caption': caption,
    'frameStyle': frameStyle,
    if (storagePath != null) 'storagePath': storagePath,
  };

  factory ImageBlockPayload.fromJson(Map<String, dynamic> json) {
    return ImageBlockPayload(
      assetId: json['assetId'] as String?,
      path: json['path'] as String?,
      originalWidth: json['originalWidth'] as int?,
      originalHeight: json['originalHeight'] as int?,
      caption: json['caption'] as String?,
      frameStyle: json['frameStyle'] as String? ?? 'none',
      storagePath: json['storagePath'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Audio block payload
class AudioBlockPayload {
  final String? assetId;
  final String? path;
  final int? durationMs; // Duration in milliseconds
  final String? storagePath; // Cloud Storage path

  AudioBlockPayload({
    this.assetId,
    this.path,
    this.durationMs,
    this.storagePath,
  });

  Map<String, dynamic> toJson() => {
    if (assetId != null) 'assetId': assetId,
    if (path != null) 'path': path,
    if (durationMs != null) 'durationMs': durationMs,
    if (storagePath != null) 'storagePath': storagePath,
  };

  factory AudioBlockPayload.fromJson(Map<String, dynamic> json) {
    return AudioBlockPayload(
      assetId: json['assetId'] as String?,
      path: json['path'] as String?,
      durationMs: json['durationMs'] as int?,
      storagePath: json['storagePath'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Video block payload
class VideoBlockPayload {
  final String? assetId;
  final String? path;
  final String? storagePath;
  final int? durationMs;
  final String? caption;

  VideoBlockPayload({
    this.assetId,
    this.path,
    this.storagePath,
    this.durationMs,
    this.caption,
  });

  Map<String, dynamic> toJson() => {
    if (assetId != null) 'assetId': assetId,
    if (path != null) 'path': path,
    if (storagePath != null) 'storagePath': storagePath,
    if (durationMs != null) 'durationMs': durationMs,
    if (caption != null) 'caption': caption,
  };

  factory VideoBlockPayload.fromJson(Map<String, dynamic> json) {
    return VideoBlockPayload(
      assetId: json['assetId'] as String?,
      path: json['path'] as String?,
      storagePath: json['storagePath'] as String?,
      durationMs: json['durationMs'] as int?,
      caption: json['caption'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
