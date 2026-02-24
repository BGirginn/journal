import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'dart:ui' as ui;
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/features/editor/widgets/sticker_picker.dart';
import 'package:journal_app/features/editor/widgets/image_picker_service.dart';
import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';
import 'package:journal_app/features/editor/widgets/video_block_widget.dart';
import 'package:journal_app/features/editor/widgets/text_edit_dialog.dart';
import 'package:journal_app/features/editor/widgets/audio_block_widget.dart';
import 'package:journal_app/features/editor/services/audio_recorder_service.dart';
import 'package:journal_app/features/editor/widgets/audio_recording_dialog.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/core/database/firestore_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/preview/page_preview_screen.dart';
import 'package:journal_app/features/export/services/pdf_export_service.dart';
import 'package:journal_app/features/editor/widgets/tag_editor_widget.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_elevation.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/theme/tokens/brand_spacing.dart';
import 'package:journal_app/l10n/app_localizations.dart';

part 'editor_screen/editor_screen_toolbar.dart';
part 'editor_screen/editor_screen_canvas.dart';
part 'editor_screen/editor_screen_actions.dart';
part 'editor_screen/editor_screen_gestures.dart';
part 'editor_screen/editor_screen_types.dart';

/// Complete editor with working transform and save
class EditorScreen extends ConsumerStatefulWidget {
  final Journal journal;
  final model.Page page;

  const EditorScreen({super.key, required this.journal, required this.page});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late NotebookTheme _theme;
  List<Block> _blocks = [];
  List<InkStrokeData> _strokes = [];
  bool _isLoading = true;
  bool _isDirty = false;
  ui.Image? _bgImage;

  // Editor state
  EditorMode _mode = EditorMode.select;
  String? _selectedBlockId;
  Color _penColor = Colors.black;
  double _penWidth = 2.0;
  Offset? _eraserPreviewPoint;

  // Transform state
  Offset? _dragStart;
  Offset? _originalPosition;
  _HandleType? _activeHandle;
  final TransformationController _pageTransformController =
      TransformationController();
  int _activePointerCount = 0;
  Size? _canvasSize;

  _ScaleTarget _activeScaleTarget = _ScaleTarget.none;
  String? _activeScaleBlockId;
  _BlockScaleSnapshot? _scaleStartBlockSnapshot;
  Matrix4? _scaleStartPageMatrix;

  void _applyState(VoidCallback updater) {
    if (!mounted) {
      return;
    }
    setState(updater);
  }

  void _reportSyncIssue({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typedError = SyncError(
      code: 'editor_sync_$operation',
      message: 'Editor sync operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    ref
        .read(appLoggerProvider)
        .warn(
          'editor_sync_issue',
          data: {'operation': operation, ...extra},
          error: typedError,
          stackTrace: stackTrace,
        );
    ref
        .read(telemetryServiceProvider)
        .track(
          'editor_sync_issue',
          params: {
            'operation': operation,
            'error_code': typedError.code,
            ...extra,
          },
        );
  }

  @override
  void initState() {
    super.initState();
    _theme = NostalgicThemes.getById(widget.journal.coverStyle);
    final pageLooksDark =
        _theme.visuals.assetPath != null ||
        _theme.visuals.pageColor.computeLuminance() < 0.3;
    if (pageLooksDark) {
      _penColor = Colors.white;
    }
    _loadContent();
  }

  @override
  void dispose() {
    _pageTransformController.value = Matrix4.identity();
    _pageTransformController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final blockDao = ref.read(blockDaoProvider);
    final blocks = await blockDao.getBlocksForPage(widget.page.id);

    // Load background image if theme has one
    ui.Image? bgImage;
    if (_theme.visuals.assetPath != null) {
      try {
        bgImage = await _loadImage(
          _theme.visuals.assetPath!,
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Failed to load background image: $e');
      }
    }

    if (mounted) {
      setState(() {
        _blocks = blocks;
        _bgImage = bgImage;
        _isLoading = false;
      });
    }

    // Load ink strokes from page
    final pageDao = ref.read(pageDaoProvider);
    final page = await pageDao.getPageById(widget.page.id);
    if (page != null && page.inkData.isNotEmpty) {
      setState(() {
        _strokes = InkStrokeData.decodeStrokes(page.inkData);
      });
    }
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final completer = Completer<ui.Image>();
    final imageProvider = AssetImage(assetPath);
    final stream = imageProvider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
        }
        stream.removeListener(listener);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final stopwatch = Stopwatch()..start();
    // Save ink strokes to page
    final pageDao = ref.read(pageDaoProvider);
    final inkJson = InkStrokeData.encodeStrokes(_strokes);
    await pageDao.updateInkData(widget.page.id, inkJson);

    // Save blocks in batch
    final blockDao = ref.read(blockDaoProvider);
    await blockDao.updateBlocks(_blocks);

    // Sync to Firestore
    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      final updatedPage = widget.page.copyWith(
        inkData: inkJson,
        updatedAt: DateTime.now(),
      );
      await firestoreService.updatePage(updatedPage);

      for (final block in _blocks) {
        await firestoreService.updateBlock(
          block,
          journalId: widget.page.journalId,
        );
      }
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'save_firestore',
        error: e,
        stackTrace: st,
        extra: {'block_count': _blocks.length},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editorSaveLocalCloudFail(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    stopwatch.stop();

    ref
        .read(telemetryServiceProvider)
        .track(
          'save_duration',
          params: {
            'duration_ms': stopwatch.elapsedMilliseconds,
            'block_count': _blocks.length,
            'stroke_count': _strokes.length,
          },
        );

    setState(() => _isDirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editorSaved),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _insertBlockWithSync(Block block) async {
    await ref.read(blockDaoProvider).insertBlock(block);
    if (mounted && _blocks.every((candidate) => candidate.id != block.id)) {
      setState(() {
        _blocks.add(block);
      });
    }
    try {
      await ref
          .read(firestoreServiceProvider)
          .createBlock(block, journalId: widget.page.journalId);
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'create_block',
        error: e,
        stackTrace: st,
        extra: {'block_id': block.id},
      );
    }
  }

  Future<void> _updateBlockWithSync(Block block) async {
    await ref.read(blockDaoProvider).updateBlock(block);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateBlock(block, journalId: widget.page.journalId);
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'update_block',
        error: e,
        stackTrace: st,
        extra: {'block_id': block.id},
      );
    }
  }

  Future<void> _updatePayloadWithSync(
    String blockId,
    String payloadJson,
  ) async {
    final blockDao = ref.read(blockDaoProvider);
    await blockDao.updatePayload(blockId, payloadJson);

    Block? updatedBlock;
    final localIndex = _blocks.indexWhere(
      (candidate) => candidate.id == blockId,
    );
    if (localIndex != -1) {
      final nextBlock = _blocks[localIndex].copyWith(payloadJson: payloadJson);
      updatedBlock = nextBlock;
      if (mounted) {
        setState(() {
          _blocks[localIndex] = nextBlock;
        });
      } else {
        _blocks[localIndex] = nextBlock;
      }
    } else {
      updatedBlock = await blockDao.getById(blockId);
    }

    if (updatedBlock == null) {
      return;
    }

    try {
      await ref
          .read(firestoreServiceProvider)
          .updateBlock(updatedBlock, journalId: widget.page.journalId);
    } catch (e, st) {
      _reportSyncIssue(
        operation: 'update_payload',
        error: e,
        stackTrace: st,
        extra: {'block_id': blockId},
      );
    }
  }

  double get _currentPageScale =>
      _pageTransformController.value.getMaxScaleOnAxis();

  bool get _enablePagePan =>
      _mode == EditorMode.select &&
      _selectedBlockId == null &&
      (_currentPageScale > 1.001 || _activeScaleTarget == _ScaleTarget.page);

  bool get _enablePageScale => _mode == EditorMode.select;

  Offset _toScene(Offset viewportPoint) {
    return _pageTransformController.toScene(viewportPoint);
  }

  Offset _toSceneDelta(Offset viewportDelta) {
    final scale = _currentPageScale.clamp(1.0, 4.0);
    return Offset(viewportDelta.dx / scale, viewportDelta.dy / scale);
  }

  void _onPointerDown(PointerDownEvent _) {
    final next = _activePointerCount + 1;
    if (next != _activePointerCount) {
      setState(() => _activePointerCount = next);
    }
  }

  void _onPointerUp(PointerEvent _) {
    final next = max(0, _activePointerCount - 1);
    if (next != _activePointerCount) {
      setState(() {
        _activePointerCount = next;
        if (next < 2 && _activeScaleTarget == _ScaleTarget.page) {
          _activeScaleTarget = _ScaleTarget.none;
        }
      });
    }
  }

  void _resetPageZoom() {
    _pageTransformController.value = Matrix4.identity();
    setState(() {
      _activeScaleTarget = _ScaleTarget.none;
    });
  }

  bool _isPointInsideBlock({
    required Offset scenePoint,
    required Block block,
    required Size pageSize,
  }) {
    final center = Offset(
      (block.x + (block.width / 2)) * pageSize.width,
      (block.y + (block.height / 2)) * pageSize.height,
    );
    final local = scenePoint - center;
    final radians = -block.rotation * pi / 180;
    final rotated = Offset(
      local.dx * cos(radians) - local.dy * sin(radians),
      local.dx * sin(radians) + local.dy * cos(radians),
    );

    return rotated.dx.abs() <= (block.width * pageSize.width / 2) &&
        rotated.dy.abs() <= (block.height * pageSize.height / 2);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final isMultiTouch = details.pointerCount >= 2;
    final isZoomed = _currentPageScale > 1.001;
    if (_mode != EditorMode.select || (!isMultiTouch && !isZoomed)) {
      return;
    }
    if (!isMultiTouch && _selectedBlockId != null) {
      return;
    }

    _scaleStartPageMatrix = Matrix4.copy(_pageTransformController.value);

    if (_selectedBlockId == null) {
      _activeScaleTarget = _ScaleTarget.page;
      setState(() {});
      return;
    }

    if (_canvasSize == null) {
      return;
    }

    final pageSize = _canvasSize!;
    final selectedIndex = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (selectedIndex == -1) {
      _activeScaleTarget = _ScaleTarget.page;
      _selectedBlockId = null;
      setState(() {});
      return;
    }

    final selectedBlock = _blocks[selectedIndex];
    final sceneFocal = _toScene(details.localFocalPoint);
    final startsOnSelectedBlock = _isPointInsideBlock(
      scenePoint: sceneFocal,
      block: selectedBlock,
      pageSize: pageSize,
    );

    if (startsOnSelectedBlock && isMultiTouch) {
      _activeScaleTarget = _ScaleTarget.block;
      _activeScaleBlockId = selectedBlock.id;
      _scaleStartBlockSnapshot = _BlockScaleSnapshot.fromBlock(selectedBlock);
    } else {
      _activeScaleTarget = _ScaleTarget.page;
      _activeScaleBlockId = null;
      _scaleStartBlockSnapshot = null;
      _selectedBlockId = null;
    }

    setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_mode != EditorMode.select) return;

    if (_activeScaleTarget == _ScaleTarget.block) {
      _applyBlockPinchTransform(details);
      if (_scaleStartPageMatrix != null) {
        _pageTransformController.value = Matrix4.copy(_scaleStartPageMatrix!);
      }
      return;
    }

    if (_activeScaleTarget == _ScaleTarget.none &&
        _scaleStartPageMatrix != null) {
      _pageTransformController.value = Matrix4.copy(_scaleStartPageMatrix!);
      return;
    }

    if (_activeScaleTarget == _ScaleTarget.page) {
      setState(() {});
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_activeScaleTarget == _ScaleTarget.block &&
        _activeScaleBlockId != null) {
      final idx = _blocks.indexWhere((b) => b.id == _activeScaleBlockId);
      if (idx != -1) {
        _updateBlockWithSync(_blocks[idx]);
      }
    }

    setState(() {
      _activeScaleTarget = _ScaleTarget.none;
      _activeScaleBlockId = null;
      _scaleStartBlockSnapshot = null;
      _scaleStartPageMatrix = null;
    });
  }

  void _applyBlockPinchTransform(ScaleUpdateDetails details) {
    if (_canvasSize == null ||
        _activeScaleBlockId == null ||
        _scaleStartBlockSnapshot == null) {
      return;
    }

    final snapshot = _scaleStartBlockSnapshot!;
    final index = _blocks.indexWhere((b) => b.id == _activeScaleBlockId);
    if (index == -1) return;

    final centerX = snapshot.x + (snapshot.width / 2);
    final centerY = snapshot.y + (snapshot.height / 2);
    final scaledWidth = (snapshot.width * details.scale).clamp(0.05, 0.9);
    final scaledHeight = (snapshot.height * details.scale).clamp(0.05, 0.9);
    final maxX = max(0.0, 1.0 - scaledWidth);
    final maxY = max(0.0, 1.0 - scaledHeight);
    final x = (centerX - (scaledWidth / 2)).clamp(0.0, maxX);
    final y = (centerY - (scaledHeight / 2)).clamp(0.0, maxY);
    final rotation = snapshot.rotation + (details.rotation * 180 / pi);

    setState(() {
      _blocks[index] = _blocks[index].copyWith(
        x: x,
        y: y,
        width: scaledWidth,
        height: scaledHeight,
        rotation: rotation,
      );
      _isDirty = true;
    });
  }

  _InsertPlacement _computeInsertPlacement({
    required double baseWidth,
    required double baseHeight,
  }) {
    final pageSize = _canvasSize;
    final scale = _currentPageScale.clamp(1.0, 4.0);
    final width = (baseWidth / scale).clamp(0.05, 0.9);
    final height = (baseHeight / scale).clamp(0.05, 0.9);

    if (pageSize == null || pageSize.isEmpty) {
      final fallbackX = ((0.5 - width / 2)).clamp(0.0, 1.0 - width);
      final fallbackY = ((0.5 - height / 2)).clamp(0.0, 1.0 - height);
      return _InsertPlacement(
        x: fallbackX,
        y: fallbackY,
        width: width,
        height: height,
      );
    }

    final viewportCenter = Offset(pageSize.width / 2, pageSize.height / 2);
    final sceneCenter = _toScene(viewportCenter);
    final normalizedCenterX = sceneCenter.dx / pageSize.width;
    final normalizedCenterY = sceneCenter.dy / pageSize.height;
    final x = (normalizedCenterX - (width / 2)).clamp(0.0, 1.0 - width);
    final y = (normalizedCenterY - (height / 2)).clamp(0.0, 1.0 - height);
    return _InsertPlacement(x: x, y: y, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final topBarSolid =
        _selectedBlockId != null ||
        _mode != EditorMode.select ||
        _currentPageScale > 1.001;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isDirty) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: semantic.background,
        appBar: AppBar(
          title: Text(l10n.editorPageTitle(widget.page.pageIndex + 1)),
          centerTitle: true,
          backgroundColor: colorScheme.surface.withValues(
            alpha: topBarSolid ? 0.96 : 0.72,
          ),
          foregroundColor: colorScheme.onSurface,
          elevation: topBarSolid ? 1 : 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isDirty) {
                final shouldPop = await _showUnsavedChangesDialog();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_selectedBlockId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.editorToolDelete,
                onPressed: _deleteSelectedBlock,
              ),
            // Share/Export button
            PopupMenuButton<String>(
              icon: const Icon(Icons.share),
              tooltip: l10n.editorTooltipShare,
              onSelected: (value) async {
                if (value == 'pdf') {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.editorPdfPreparing)),
                    );
                    final pageDao = ref.read(pageDaoProvider);
                    final pages = await pageDao.getPagesForJournal(
                      widget.journal.id,
                    );
                    final exportService = PdfExportService(
                      ref.read(blockDaoProvider),
                    );
                    await exportService.exportJournal(widget.journal, pages);
                  } catch (e, st) {
                    _reportSyncIssue(
                      operation: 'export_pdf',
                      error: e,
                      stackTrace: st,
                      extra: {'journal_id': widget.journal.id},
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.editorErrorWithMessage(e.toString()),
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(l10n.editorExportPdf),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            // Preview button
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PagePreviewScreen(
                      journal: widget.journal,
                      page: widget.page,
                      initialBlocks: List<Block>.from(_blocks),
                      initialStrokes: List<InkStrokeData>.from(_strokes),
                    ),
                  ),
                );
              },
              tooltip: l10n.editorTooltipPreview,
            ),
            // Save button
            IconButton(
              icon: Icon(_isDirty ? Icons.save : Icons.cloud_done),
              onPressed: _isDirty ? _save : null,
              tooltip: l10n.editorTooltipSave,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(child: _buildCanvas()),
                        if (_mode == EditorMode.draw ||
                            _mode == EditorMode.erase)
                          _buildPenOptions(),
                        const SizedBox(height: 98),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildToolbar(topBarSolid),
                  ),
                ],
              ),
      ),
    );
  }
}
