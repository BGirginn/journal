part of '../editor_screen.dart';

extension _EditorCanvasExtension on _EditorScreenState {
  Widget _buildCanvas() {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageSize = Size(constraints.maxWidth, constraints.maxHeight);
        _canvasSize = pageSize;
        final sortedBlocks = List<Block>.from(_blocks)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: InteractiveViewer(
            transformationController: _pageTransformController,
            minScale: 1.0,
            maxScale: 4.0,
            panEnabled: _enablePagePinch,
            scaleEnabled: _enablePagePinch,
            onInteractionStart: _onScaleStart,
            onInteractionUpdate: _onScaleUpdate,
            onInteractionEnd: _onScaleEnd,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _onTapDown(d, pageSize),
              onPanStart: (d) => _onPanStart(d, pageSize),
              onPanUpdate: (d) => _onPanUpdate(d, pageSize),
              onPanEnd: (d) => _onPanEnd(),
              onPanCancel: _onPanEnd,
              onTapUp: (d) => _onTapUp(d, pageSize),
              child: Container(
                decoration: BoxDecoration(
                  color: _theme.visuals.pageColor,
                  borderRadius: _theme.visuals.cornerRadius,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.14),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _theme.visuals.cornerRadius,
                  child: Stack(
                    children: [
                      // Page background
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: NostalgicPagePainter(
                            theme: _theme,
                            preloadedImage: _bgImage,
                          ),
                          size: Size.infinite,
                        ),
                      ),

                      // Blocks
                      IgnorePointer(
                        ignoring:
                            _mode == EditorMode.draw ||
                            _mode == EditorMode.erase,
                        child: Stack(
                          children: [
                            ...sortedBlocks.map(
                              (block) => _buildBlock(block, pageSize),
                            ),
                          ],
                        ),
                      ),

                      // Ink strokes should stay visible above full-page image/asset blocks.
                      RepaintBoundary(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: OptimizedInkPainter(
                              strokes: _strokes,
                              currentStroke: null,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),

                      if (_mode == EditorMode.erase &&
                          _eraserPreviewPoint != null)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _EraserPreviewPainter(
                              point: _eraserPreviewPoint!,
                              radius: _eraseRadius,
                              color:
                                  (_theme.visuals.pageColor.computeLuminance() <
                                      0.45
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface),
                            ),
                            size: Size.infinite,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editBlock(Block block) async {
    if (block.type == BlockType.text) {
      final payload = TextBlockPayload.fromJson(block.payload);
      final newPayload = await showDialog<TextBlockPayload>(
        context: context,
        builder: (context) => TextEditDialog(initialPayload: payload),
      );

      if (newPayload != null) {
        final newBlock = block.copyWith(payloadJson: newPayload.toJsonString());
        _updateBlockWithSync(newBlock);
      }
    }
  }

  Widget _buildBlock(Block block, Size pageSize) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = block.id == _selectedBlockId;
    final left = block.x * pageSize.width;
    final top = block.y * pageSize.height;
    final width = block.width * pageSize.width;
    final height = block.height * pageSize.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _applyState(() => _selectedBlockId = block.id),
        onDoubleTap: () => _editBlock(block),
        child: Transform.rotate(
          angle: block.rotation * pi / 180,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Content
                Positioned.fill(child: _buildBlockContent(block, pageSize)),

                // Selection handles
                if (isSelected) ...[
                  // Corner handles for resize
                  _buildHandle(
                    block,
                    _HandleType.topLeft,
                    -6,
                    -6,
                    null,
                    null,
                    pageSize,
                  ),
                  _buildHandle(
                    block,
                    _HandleType.topRight,
                    null,
                    -6,
                    -6,
                    null,
                    pageSize,
                  ),
                  _buildHandle(
                    block,
                    _HandleType.bottomLeft,
                    -6,
                    null,
                    null,
                    -6,
                    pageSize,
                  ),
                  _buildHandle(
                    block,
                    _HandleType.bottomRight,
                    null,
                    null,
                    -6,
                    -6,
                    pageSize,
                  ),
                  // Rotate handle
                  Positioned(
                    left: width / 2 - 24,
                    top: -44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) {
                        _activeHandle = _HandleType.rotate;
                      },
                      onPanUpdate: (d) => _onRotate(block, d, pageSize),
                      onPanEnd: (_) => _activeHandle = null,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rotate_right,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(
    Block block,
    _HandleType type,
    double? left,
    double? top,
    double? right,
    double? bottom,
    Size pageSize,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      left: left != null ? left - 18 : null,
      top: top != null ? top - 18 : null,
      right: right != null ? right - 18 : null,
      bottom: bottom != null ? bottom - 18 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (d) {
          _activeHandle = type;
          _originalPosition = Offset(block.x, block.y);
        },
        onPanUpdate: (d) => _onResize(block, d, type, pageSize),
        onPanEnd: (_) => _activeHandle = null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockContent(Block block, Size pageSize) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    switch (block.type) {
      case BlockType.text:
        final payload = TextBlockPayload.fromJson(block.payload);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            payload.content.isEmpty
                ? l10n.editorTextPlaceholder
                : payload.content,
            style: TextStyle(
              fontSize: 14,
              color: payload.content.isEmpty
                  ? colorScheme.onSurfaceVariant
                  : (isDark ? Colors.white : _theme.visuals.textColor),
            ),
          ),
        );
      case BlockType.video:
        final payload = VideoBlockPayload.fromJson(block.payload);
        return VideoBlockWidget(path: payload.path ?? '', isReadOnly: true);
      case BlockType.image:
        final payload = ImageBlockPayload.fromJson(block.payload);
        if (payload.path != null) {
          final path = payload.path!;
          // Calculate dimensions from pageSize instead of MediaQuery
          final width = block.width * pageSize.width;
          final height = block.height * pageSize.height;
          if (path.startsWith('assets/')) {
            return ImageFrameWidget(
              imageProvider: AssetImage(path),
              frameStyle: payload.frameStyle,
              width: width,
              height: height,
            );
          }

          final file = File(path);
          if (file.existsSync()) {
            return ImageFrameWidget(
              imageProvider: FileImage(file),
              frameStyle: payload.frameStyle,
              width: width,
              height: height,
            );
          }
        }

        if (payload.storagePath != null) {
          final width = block.width * pageSize.width;
          final height = block.height * pageSize.height;
          return FutureBuilder<String?>(
            future: ref
                .read(storageServiceProvider)
                .getDownloadUrl(payload.storagePath!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData && snapshot.data != null) {
                return ImageFrameWidget(
                  imageProvider: NetworkImage(snapshot.data!),
                  frameStyle: payload.frameStyle,
                  width: width,
                  height: height,
                );
              }

              return Container(
                color: colorScheme.surfaceContainer,
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          );
        }
        return Container(
          color: colorScheme.surfaceContainer,
          child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
        );
      case BlockType.audio:
        final payload = AudioBlockPayload.fromJson(block.payload);
        return AudioBlockWidget(
          path: payload.path ?? '',
          durationMs: payload.durationMs,
        );
    }
  }
}
