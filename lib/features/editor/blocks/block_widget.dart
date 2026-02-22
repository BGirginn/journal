import 'dart:math';
import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/widgets/audio_block_widget.dart';

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';
import 'package:journal_app/features/editor/widgets/video_block_widget.dart';

/// Base block widget that renders any block type
class BlockWidget extends ConsumerWidget {
  final Block block;
  final Size pageSize;
  final bool isSelected;
  final VoidCallback? onDoubleTap;
  final int? cacheWidth;
  final int? cacheHeight;

  const BlockWidget({
    super.key,
    required this.block,
    required this.pageSize,
    required this.isSelected,
    this.onDoubleTap,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Convert normalized coordinates to pixel positions
    final left = block.x * pageSize.width;
    final top = block.y * pageSize.height;
    final width = block.width * pageSize.width;
    final height = block.height * pageSize.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Transform.rotate(
          angle: block.rotation * pi / 180,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Block content
                Positioned.fill(child: _buildBlockContent(context)),

                // Selection handles
                if (isSelected) ..._buildHandles(width, height),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    switch (block.type) {
      case BlockType.text:
        return _TextBlockContent(block: block);
      case BlockType.image:
        return _ImageBlockContent(
          block: block,
          pageSize: pageSize,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );

      case BlockType.audio:
        final payload = AudioBlockPayload.fromJson(block.payload);
        return AudioBlockWidget(
          path: payload.path ?? '',
          durationMs: payload.durationMs,
        );
      case BlockType.video:
        final payload = VideoBlockPayload.fromJson(block.payload);
        return VideoBlockWidget(path: payload.path ?? '');
    }
  }

  List<Widget> _buildHandles(double width, double height) {
    const handleSize = 12.0;
    const halfHandle = handleSize / 2;

    return [
      // Top-left
      const Positioned(
        left: -halfHandle,
        top: -halfHandle,
        child: _Handle(size: handleSize),
      ),
      // Top-right
      const Positioned(
        right: -halfHandle,
        top: -halfHandle,
        child: _Handle(size: handleSize),
      ),
      // Bottom-left
      const Positioned(
        left: -halfHandle,
        bottom: -halfHandle,
        child: _Handle(size: handleSize),
      ),
      // Bottom-right
      const Positioned(
        right: -halfHandle,
        bottom: -halfHandle,
        child: _Handle(size: handleSize),
      ),
      // Rotate handle
      Positioned(
        left: width / 2 - halfHandle,
        top: -30,
        child: const _Handle(
          size: handleSize,
          icon: Icons.rotate_right,
          isRotate: true,
        ),
      ),
    ];
  }
}

/// Resize/rotate handle widget
class _Handle extends StatelessWidget {
  final double size;
  final IconData? icon;
  final bool isRotate;

  const _Handle({required this.size, this.icon, this.isRotate = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.primary, width: 2),
        shape: isRotate ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRotate ? null : BorderRadius.circular(2),
      ),
      child: icon != null
          ? Icon(icon, size: size - 4, color: colorScheme.primary)
          : null,
    );
  }
}

/// Text block content
class _TextBlockContent extends StatelessWidget {
  final Block block;

  const _TextBlockContent({required this.block});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final payload = TextBlockPayload.fromJson(block.payload);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        payload.content,
        style: TextStyle(
          fontSize: payload.fontSize,
          color: colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 10,
      ),
    );
  }
}

/// Image block content
class _ImageBlockContent extends ConsumerWidget {
  final Block block;
  final Size pageSize;
  final int? cacheWidth;
  final int? cacheHeight;

  const _ImageBlockContent({
    required this.block,
    required this.pageSize,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = ImageBlockPayload.fromJson(block.payload);
    final width = block.width * pageSize.width;
    final height = block.height * pageSize.height;

    // 1. Try Local Path
    if (payload.path != null) {
      final path = payload.path!;
      if (path.startsWith('assets/')) {
        return ImageFrameWidget(
          imageProvider: AssetImage(path),
          frameStyle: payload.frameStyle,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );
      }

      final file = File(path);
      if (file.existsSync()) {
        return ImageFrameWidget(
          imageProvider: FileImage(file),
          frameStyle: payload.frameStyle,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        );
      }
    }

    // 2. Try Cloud Storage
    if (payload.storagePath != null) {
      final storageService = ref.watch(storageServiceProvider);
      return FutureBuilder<String?>(
        future: storageService.getDownloadUrl(payload.storagePath!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            // We need ImageFrameWidget to support network URL or we replicate it
            // For now, assuming ImageFrameWidget is local-only (File image),
            // but we can use CachedNetworkImage directly if style is none,
            // or standard ImageFrameWidget if we download it.
            // Ideally ImageFrameWidget should accept an ImageProvider.
            // Let's us CachedNetworkImage for now.
            return ImageFrameWidget(
              imageProvider: NetworkImage(snapshot.data!),
              frameStyle: payload.frameStyle,
              width: width,
              height: height,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
            );
          }
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    // 3. Fallback
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Görsel Bulunamadı',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
