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
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/features/preview/page_preview_screen.dart';
import 'package:journal_app/features/export/services/pdf_export_service.dart';
import 'package:journal_app/features/editor/widgets/drawing_canvas_screen.dart';
import 'package:journal_app/features/editor/widgets/tag_editor_widget.dart';
import 'package:journal_app/core/services/notification_service.dart';

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
        bgImage = await _loadImage(_theme.visuals.assetPath!);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yerel kaydedildi, bulut senkronizasyonu başarısız: $e',
            ),
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
        const SnackBar(
          content: Text('Kaydedildi ✓'),
          duration: Duration(seconds: 1),
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
    } catch (_) {
      // Offline-first: local write remains source of truth.
    }
  }

  Future<void> _updateBlockWithSync(Block block) async {
    await ref.read(blockDaoProvider).updateBlock(block);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateBlock(block, journalId: widget.page.journalId);
    } catch (_) {
      // Offline-first: cloud retry handled by oplog queue.
    }
  }

  Future<void> _updatePayloadWithSync(
    String blockId,
    String payloadJson,
  ) async {
    await ref.read(blockDaoProvider).updatePayload(blockId, payloadJson);
    try {
      final block = _blocks
          .firstWhere((candidate) => candidate.id == blockId)
          .copyWith(payloadJson: payloadJson);
      await ref
          .read(firestoreServiceProvider)
          .updateBlock(block, journalId: widget.page.journalId);
    } catch (_) {
      // Ignore and rely on sync retry.
    }
  }

  double get _currentPageScale =>
      _pageTransformController.value.getMaxScaleOnAxis();

  bool get _enablePagePinch =>
      _mode == EditorMode.select &&
      _activePointerCount >= 2 &&
      _activeScaleTarget != _ScaleTarget.block;

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
    if (!_enablePagePinch || _canvasSize == null || _selectedBlockId == null) {
      if (_mode == EditorMode.select && _activePointerCount >= 2) {
        _activeScaleTarget = _ScaleTarget.page;
        _scaleStartPageMatrix = Matrix4.copy(_pageTransformController.value);
      }
      return;
    }

    final pageSize = _canvasSize!;
    final selectedIndex = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (selectedIndex == -1) {
      _activeScaleTarget = _ScaleTarget.page;
      _scaleStartPageMatrix = Matrix4.copy(_pageTransformController.value);
      return;
    }

    final selectedBlock = _blocks[selectedIndex];
    final sceneFocal = _toScene(details.localFocalPoint);
    final startsOnSelectedBlock = _isPointInsideBlock(
      scenePoint: sceneFocal,
      block: selectedBlock,
      pageSize: pageSize,
    );

    if (startsOnSelectedBlock) {
      _scaleStartPageMatrix = Matrix4.copy(_pageTransformController.value);
      _activeScaleTarget = _ScaleTarget.block;
      _activeScaleBlockId = selectedBlock.id;
      _scaleStartBlockSnapshot = _BlockScaleSnapshot.fromBlock(selectedBlock);
    } else {
      _activeScaleTarget = _ScaleTarget.page;
      _scaleStartPageMatrix = Matrix4.copy(_pageTransformController.value);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        backgroundColor: isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text('Sayfa ${widget.page.pageIndex + 1}'),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
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
            // Share/Export button
            PopupMenuButton<String>(
              icon: const Icon(Icons.share),
              tooltip: 'Paylaş',
              onSelected: (value) async {
                if (value == 'pdf') {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('PDF hazırlanıyor...')),
                    );
                    final pageDao = ref.read(pageDaoProvider);
                    final pages = await pageDao.getPagesForJournal(
                      widget.journal.id,
                    );
                    final exportService = PdfExportService(
                      ref.read(blockDaoProvider),
                    );
                    await exportService.exportJournal(widget.journal, pages);
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('PDF Olarak Dışa Aktar'),
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
              tooltip: 'Önizle',
            ),
            // Save button
            IconButton(
              icon: Icon(_isDirty ? Icons.save : Icons.cloud_done),
              onPressed: _isDirty ? _save : null,
              tooltip: 'Kaydet',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildToolbar(isDark),
                  if (_mode == EditorMode.draw || _mode == EditorMode.erase)
                    _buildPenOptions(),
                  Expanded(child: _buildCanvas()),
                ],
              ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolBtn(
            Icons.pan_tool_alt,
            'Seç',
            _mode == EditorMode.select,
            () => setState(() {
              _mode = EditorMode.select;
              _eraserPreviewPoint = null;
            }),
          ),
          _ToolBtn(
            Icons.text_fields,
            'Metin',
            _mode == EditorMode.text,
            () => _addTextBlock(),
          ),
          _ToolBtn(
            Icons.edit,
            'Çiz',
            _mode == EditorMode.draw,
            () => setState(() {
              _mode = EditorMode.draw;
              _eraserPreviewPoint = null;
              if (_penColor == Colors.black) {
                final pageLooksDark =
                    _theme.visuals.assetPath != null ||
                    _theme.visuals.pageColor.computeLuminance() < 0.3;
                if (pageLooksDark) {
                  _penColor = Colors.white;
                }
              }
            }),
          ),
          _ToolBtn(
            Icons.cleaning_services_outlined,
            'Silgi',
            _mode == EditorMode.erase,
            () => setState(() => _mode = EditorMode.erase),
          ),
          _ToolBtn(Icons.add_circle, 'Medya', false, _showMediaPicker),
          _ToolBtn(
            Icons.emoji_emotions_outlined,
            'Sticker',
            false,
            _handleStickerPicker,
          ),
          _ToolBtn(Icons.label_outline, 'Etiket', false, _showTagEditor),
          if (_mode == EditorMode.select)
            _ToolBtn(Icons.filter_1, '1x', false, _resetPageZoom),
          if (_selectedBlockId != null) ...[
            if (_getSelectedBlockType() == BlockType.image) ...[
              _ToolBtn(Icons.rotate_right, 'Döndür', false, _showRotateDialog),
              _ToolBtn(Icons.style, 'Çerçeve', false, _showFramePicker),
            ],
            _ToolBtn(Icons.delete, 'Sil', false, _deleteSelectedBlock),
          ],
        ],
      ),
    );
  }

  Future<void> _handleStickerPicker() async {
    final sticker = await showStickerPicker(context);
    if (sticker != null) {
      _insertSticker(sticker);
    }
  }

  void _insertSticker(Sticker sticker) {
    if (!mounted) return;

    final id = const Uuid().v4();
    final placement = sticker.isCustom
        ? _computeInsertPlacement(baseWidth: 0.4, baseHeight: 0.4)
        : _computeInsertPlacement(baseWidth: 0.2, baseHeight: 0.1);
    Block block;

    if (sticker.isCustom) {
      // Custom sticker treated as Image Block
      block = Block(
        id: id,
        pageId: widget.page.id,
        type: BlockType.image,
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
        rotation: 0,
        zIndex: _blocks.length,
        payloadJson: ImageBlockPayload(path: sticker.asset).toJsonString(),
      );
    } else {
      // Built-in sticker (Emoji/Text) treated as Text Block
      // We center it roughly
      block = Block(
        id: id,
        pageId: widget.page.id,
        type: BlockType.text,
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
        rotation: 0,
        zIndex: _blocks.length,
        payloadJson: TextBlockPayload(
          content: sticker.asset,
          fontSize: 48, // Large font for stickers
          textAlign: 'center',
          color:
              '#${(sticker.color ?? Colors.black).toARGB32().toRadixString(16).padLeft(8, '0')}',
        ).toJsonString(),
      );
    }

    setState(() {
      _blocks.add(block);
      _isDirty = true;
    });

    _insertBlockWithSync(block);
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Medya Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Resim'),
              subtitle: const Text('Galeriden veya kameradan'),
              onTap: () {
                Navigator.pop(context);
                _addImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Video'),
              subtitle: const Text('Video kaydet veya seç'),
              onTap: () {
                Navigator.pop(context);
                _addVideoBlock();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.orange),
              title: const Text('Ses'),
              subtitle: const Text('Ses kaydı yap'),
              onTap: () {
                Navigator.pop(context);
                _recordAudio();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brush, color: Colors.purple),
              title: const Text('Çizim'),
              subtitle: const Text('Serbest çizim yapın'),
              onTap: () {
                Navigator.pop(context);
                _openDrawingCanvas();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openDrawingCanvas() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const DrawingCanvasScreen()),
    );

    if (imagePath != null && mounted) {
      final placement = _computeInsertPlacement(
        baseWidth: 0.9,
        baseHeight: 0.4,
      );
      // Insert drawing as image block
      final id = const Uuid().v4();
      final block = Block(
        id: id,
        pageId: widget.page.id,
        type: BlockType.image,
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
        rotation: 0,
        zIndex: _blocks.length,
        payloadJson: ImageBlockPayload(path: imagePath).toJsonString(),
      );

      setState(() {
        _blocks.add(block);
        _isDirty = true;
      });

      _insertBlockWithSync(block);
      NotificationService.logEvent('drawing_created');
    }
  }

  void _showTagEditor() {
    final currentTags = widget.page.tagList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sayfa Etiketleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TagEditorWidget(
              tags: currentTags,
              onTagsChanged: (newTags) {
                final tagsStr = newTags.join(',');
                final pageDao = ref.read(pageDaoProvider);
                pageDao.updatePage(
                  widget.page.copyWith(
                    tags: tagsStr,
                    updatedAt: DateTime.now(),
                  ),
                );
                setState(() => _isDirty = true);
              },
            ),
            const SizedBox(height: 8),
            const TagSuggestions(
              suggestions: [
                'anı',
                'seyahat',
                'yemek',
                'spor',
                'müzik',
                'iş',
                'aile',
              ],
              selectedTags: [],
              onTagTapped: _noOp,
            ),
          ],
        ),
      ),
    );
  }

  static void _noOp(String tag) {}

  Future<void> _addVideoBlock() async {
    final service = ImagePickerService();
    // Show dialog to choose source for video
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Galeriden Seç'),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickVideoFromGallery();
                if (file != null) {
                  _insertVideoBlock(file);
                } else if (mounted && service.lastErrorMessage != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(service.lastErrorMessage!)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video Çek'),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickVideoFromCamera();
                if (file != null) {
                  _insertVideoBlock(file);
                } else if (mounted && service.lastErrorMessage != null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(service.lastErrorMessage!)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertVideoBlock(File file) {
    if (!mounted) return;
    final placement = _computeInsertPlacement(baseWidth: 0.8, baseHeight: 0.3);

    // Create audio/video block
    // We reuse logic similar to Image but for Video
    final id = const Uuid().v4();
    final block = Block(
      id: id,
      pageId: widget.page.id,
      type: BlockType.video,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      rotation: 0,
      zIndex: _blocks.length,
      payloadJson: VideoBlockPayload(
        path: file.path,
        storagePath: null, // To be uploaded
      ).toJsonString(),
    );

    setState(() {
      _blocks.add(block);
      _isDirty = true;
    });

    _insertBlockWithSync(block);
  }

  BlockType? _getSelectedBlockType() {
    if (_selectedBlockId == null) return null;
    try {
      return _blocks.firstWhere((b) => b.id == _selectedBlockId).type;
    } catch (_) {
      return null;
    }
  }

  Widget _buildPenOptions() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final pageLooksDark =
        _theme.visuals.assetPath != null ||
        _theme.visuals.pageColor.computeLuminance() < 0.35;
    final useDarkPanel = isDarkTheme || pageLooksDark;
    final panelColor = useDarkPanel
        ? const Color(0xFF252230)
        : const Color(0xFFF6F3FC);
    final textColor = useDarkPanel
        ? const Color(0xFFF4F0FC)
        : const Color(0xFF2E2A38);
    final dividerColor = useDarkPanel
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.16);
    final selectedBg = useDarkPanel
        ? const Color(0xFF8A71E8).withValues(alpha: 0.28)
        : const Color(0xFF6C4CD8).withValues(alpha: 0.16);
    final selectedBorderColor = useDarkPanel
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Row(
        children: [
          if (_mode == EditorMode.draw) ...[
            // Colors
            ...[
              Colors.black,
              Colors.white,
              Colors.blue,
              Colors.red,
              Colors.green,
            ].map(
              (c) => GestureDetector(
                onTap: () => setState(() => _penColor = c),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    // Keep white swatch visible on light surfaces.
                    border: c == Colors.white
                        ? Border.all(color: dividerColor, width: 1.2)
                        : null,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _penColor == c
                          ? Border.all(
                              color: useDarkPanel
                                  ? Colors.white
                                  : const Color(0xFF6C4CD8),
                              width: 2.5,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(color: dividerColor),
          ] else ...[
            Icon(Icons.cleaning_services_outlined, color: textColor),
            const SizedBox(width: 8),
            Text('Silgi boyutu', style: TextStyle(color: textColor)),
            const SizedBox(width: 12),
          ],
          // Widths
          ...[2.0, 4.0, 8.0].map(
            (w) => GestureDetector(
              onTap: () => setState(() => _penWidth = w),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _penWidth == w ? selectedBg : null,
                  border: Border.all(
                    color: _penWidth == w
                        ? selectedBorderColor
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: w * 2,
                    height: w * 2,
                    decoration: BoxDecoration(
                      color: _mode == EditorMode.erase ? textColor : _penColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Clear
          IconButton(
            icon: Icon(Icons.delete_outline, color: textColor),
            onPressed: () {
              setState(() {
                _strokes = [];
                _isDirty = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
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
                      color: Colors.black.withAlpha(30),
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
                                  ? Colors.white
                                  : Colors.black),
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
    final isSelected = block.id == _selectedBlockId;
    final left = block.x * pageSize.width;
    final top = block.y * pageSize.height;
    final width = block.width * pageSize.width;
    final height = block.height * pageSize.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selectedBlockId = block.id),
        onDoubleTap: () => _editBlock(block),
        child: Transform.rotate(
          angle: block.rotation * pi / 180,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: Colors.deepPurple, width: 2)
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
                          decoration: const BoxDecoration(
                            color: Colors.deepPurple,
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
              color: Colors.white,
              border: Border.all(color: Colors.deepPurple, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockContent(Block block, Size pageSize) {
    switch (block.type) {
      case BlockType.text:
        final payload = TextBlockPayload.fromJson(block.payload);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            payload.content.isEmpty ? 'Yazı ekle...' : payload.content,
            style: TextStyle(
              fontSize: 14,
              color: payload.content.isEmpty
                  ? Colors.grey
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
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          );
        }
        return Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        );
      case BlockType.audio:
        final payload = AudioBlockPayload.fromJson(block.payload);
        return AudioBlockWidget(
          path: payload.path ?? '',
          durationMs: payload.durationMs,
        );
    }
  }

  void _onTapDown(TapDownDetails details, Size pageSize) {
    final scenePoint = _toScene(details.localPosition);
    if (_mode == EditorMode.erase) {
      _eraseAtPoint(scenePoint);
    }
  }

  void _onTapUp(TapUpDetails details, Size pageSize) {
    if (_mode == EditorMode.select) {
      // Deselect if tapping empty area
      setState(() => _selectedBlockId = null);
      return;
    }

    if (_mode == EditorMode.erase && _eraserPreviewPoint != null) {
      setState(() => _eraserPreviewPoint = null);
    }
  }

  void _onPanStart(DragStartDetails details, Size pageSize) {
    if (_mode == EditorMode.select &&
        (_activePointerCount >= 2 || _activeScaleTarget != _ScaleTarget.none)) {
      return;
    }
    final scenePoint = _toScene(details.localPosition);
    if (_mode == EditorMode.draw) {
      // Start a new immutable stroke list so painter sees a changed reference.
      final point = scenePoint;
      final stroke = InkStrokeData(
        points: [point],
        colorValue: _penColor.toARGB32(),
        width: _penWidth,
      );
      setState(() {
        _strokes = [..._strokes, stroke];
        _isDirty = true;
      });
    } else if (_mode == EditorMode.erase) {
      _eraseAtPoint(scenePoint);
    } else if (_mode == EditorMode.select && _selectedBlockId != null) {
      // Start dragging selected block
      _dragStart = scenePoint;
      final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
      _originalPosition = Offset(block.x, block.y);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size pageSize) {
    if (_mode == EditorMode.draw && _strokes.isNotEmpty) {
      // Append point immutably so CustomPainter always repaints immediately.
      final point = _toScene(details.localPosition);
      final lastStroke = _strokes.last;
      final updatedLastStroke = InkStrokeData(
        points: [...lastStroke.points, point],
        colorValue: lastStroke.colorValue,
        width: lastStroke.width,
      );
      setState(() {
        _strokes = [
          ..._strokes.sublist(0, _strokes.length - 1),
          updatedLastStroke,
        ];
        _isDirty = true;
      });
    } else if (_mode == EditorMode.erase) {
      _eraseAtPoint(_toScene(details.localPosition));
    } else if (_mode == EditorMode.select &&
        _selectedBlockId != null &&
        _dragStart != null &&
        _activeHandle == null) {
      // Move block
      final scenePosition = _toScene(details.localPosition);
      final delta = scenePosition - _dragStart!;
      final dx = delta.dx / pageSize.width;
      final dy = delta.dy / pageSize.height;

      setState(() {
        final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
        if (index != -1) {
          _blocks[index] = _blocks[index].copyWith(
            x: (_originalPosition!.dx + dx).clamp(
              0.0,
              1.0 - _blocks[index].width,
            ),
            y: (_originalPosition!.dy + dy).clamp(
              0.0,
              1.0 - _blocks[index].height,
            ),
          );
          _isDirty = true;
        }
      });
    }
  }

  void _onPanEnd() {
    _dragStart = null;
    _originalPosition = null;
    if (_eraserPreviewPoint != null) {
      setState(() => _eraserPreviewPoint = null);
    }
  }

  double get _eraseRadius => (_penWidth * 6).clamp(10.0, 36.0).toDouble();

  void _eraseAtPoint(Offset point) {
    final eraseRadius = _eraseRadius;
    final eraseRadiusSq = eraseRadius * eraseRadius;
    var changed = false;
    final next = <InkStrokeData>[];

    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

      final hit = stroke.points.any((p) {
        final dx = p.dx - point.dx;
        final dy = p.dy - point.dy;
        return (dx * dx) + (dy * dy) <= eraseRadiusSq;
      });

      if (!hit) {
        next.add(stroke);
        continue;
      }

      changed = true;
      var segment = <Offset>[];

      for (final p in stroke.points) {
        final dx = p.dx - point.dx;
        final dy = p.dy - point.dy;
        final inside = (dx * dx) + (dy * dy) <= eraseRadiusSq;

        if (inside) {
          if (segment.isNotEmpty) {
            next.add(
              InkStrokeData(
                points: List<Offset>.from(segment),
                colorValue: stroke.colorValue,
                width: stroke.width,
              ),
            );
            segment = <Offset>[];
          }
          continue;
        }

        segment.add(p);
      }

      if (segment.isNotEmpty) {
        next.add(
          InkStrokeData(
            points: List<Offset>.from(segment),
            colorValue: stroke.colorValue,
            width: stroke.width,
          ),
        );
      }
    }

    final previewPoint = _eraserPreviewPoint;
    final previewMoved =
        previewPoint == null ||
        ((previewPoint.dx - point.dx).abs() > 0.5 ||
            (previewPoint.dy - point.dy).abs() > 0.5);

    if (changed || previewMoved) {
      setState(() {
        _eraserPreviewPoint = point;
        if (changed) {
          _strokes = next;
          _isDirty = true;
        }
      });
    }
  }

  void _onResize(
    Block block,
    DragUpdateDetails details,
    _HandleType type,
    Size pageSize,
  ) {
    final sceneDelta = _toSceneDelta(details.delta);
    final delta = Offset(
      sceneDelta.dx / pageSize.width,
      sceneDelta.dy / pageSize.height,
    );

    setState(() {
      final index = _blocks.indexWhere((b) => b.id == block.id);
      if (index == -1) return;

      var newBlock = _blocks[index];

      switch (type) {
        case _HandleType.bottomRight:
          newBlock = newBlock.copyWith(
            width: (newBlock.width + delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height + delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.topLeft:
          newBlock = newBlock.copyWith(
            x: (newBlock.x + delta.dx).clamp(0.0, 0.9),
            y: (newBlock.y + delta.dy).clamp(0.0, 0.9),
            width: (newBlock.width - delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height - delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.topRight:
          newBlock = newBlock.copyWith(
            y: (newBlock.y + delta.dy).clamp(0.0, 0.9),
            width: (newBlock.width + delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height - delta.dy).clamp(0.05, 0.9),
          );
          break;
        case _HandleType.bottomLeft:
          newBlock = newBlock.copyWith(
            x: (newBlock.x + delta.dx).clamp(0.0, 0.9),
            width: (newBlock.width - delta.dx).clamp(0.05, 0.9),
            height: (newBlock.height + delta.dy).clamp(0.05, 0.9),
          );
          break;
        default:
          break;
      }

      _blocks[index] = newBlock;
      _isDirty = true;
    });
  }

  void _onRotate(Block block, DragUpdateDetails details, Size pageSize) {
    final center = Offset(
      block.x * pageSize.width + block.width * pageSize.width / 2,
      block.y * pageSize.height + block.height * pageSize.height / 2,
    );

    final angle =
        atan2(
              details.localPosition.dy - center.dy,
              details.localPosition.dx - center.dx,
            ) *
            180 /
            pi +
        90;

    setState(() {
      final index = _blocks.indexWhere((b) => b.id == block.id);
      if (index != -1) {
        _blocks[index] = _blocks[index].copyWith(rotation: angle);
        _isDirty = true;
      }
    });
  }

  void _addTextBlock() async {
    final placement = _computeInsertPlacement(baseWidth: 0.4, baseHeight: 0.08);
    final block = Block(
      pageId: widget.page.id,
      type: BlockType.text,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      zIndex: _blocks.length,
      payloadJson: TextBlockPayload(content: '').toJsonString(),
    );

    await _insertBlockWithSync(block);
    setState(() => _isDirty = true);
  }

  void _addImage() async {
    final file = await showImageSourcePicker(context);
    if (file == null) return;
    final placement = _computeInsertPlacement(
      baseWidth: 0.35,
      baseHeight: 0.25,
    );

    final block = Block(
      pageId: widget.page.id,
      type: BlockType.image,
      x: placement.x,
      y: placement.y,
      width: placement.width,
      height: placement.height,
      zIndex: _blocks.length,
      payloadJson: ImageBlockPayload(
        assetId: null,
        path: file.path,
      ).toJsonString(),
    );

    await _insertBlockWithSync(block);

    // Upload to Firebase Storage & Sync Database
    _uploadAndSyncBlock(block, file);

    setState(() => _isDirty = true);
  }

  Future<void> _uploadAndSyncBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // 1. Upload File
      final storagePath = await storageService.uploadFile(file);

      if (storagePath != null) {
        // 2. Update Local Block with Storage Path
        final currentPayload = ImageBlockPayload.fromJson(block.payload);
        final newPayload = ImageBlockPayload(
          assetId: currentPayload.assetId,
          path: currentPayload.path,
          originalWidth: currentPayload.originalWidth,
          originalHeight: currentPayload.originalHeight,
          caption: currentPayload.caption,
          frameStyle: currentPayload.frameStyle,
          storagePath: storagePath,
        );

        // Update local DB
        await _updatePayloadWithSync(block.id, newPayload.toJsonString());

        // Update valid block reference for Firestore sync
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      // 3. Sync Block Metadata to Firestore
      await firestoreService.createBlock(
        block,
        journalId: widget.page.journalId,
      );
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> _uploadAndSyncAudioBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final storagePath = await storageService.uploadFile(file);

      if (storagePath != null) {
        final currentPayload = AudioBlockPayload.fromJson(block.payload);
        final newPayload = AudioBlockPayload(
          assetId: currentPayload.assetId,
          path: currentPayload.path,
          durationMs: currentPayload.durationMs,
          storagePath: storagePath,
        );

        await _updatePayloadWithSync(block.id, newPayload.toJsonString());
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      await firestoreService.createBlock(
        block,
        journalId: widget.page.journalId,
      );
    } catch (e) {
      debugPrint('Audio Sync Error: $e');
    }
  }

  void _recordAudio() async {
    final service = AudioRecorderService();

    try {
      if (!await service.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mikrofon izni gerekli. Lütfen ayarlardan izin verin.',
              ),
            ),
          );
        }
        return;
      }

      await service.startRecording();

      if (!mounted) return;

      final path = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AudioRecordingDialog(recorder: service),
      );

      await service.dispose();

      if (path != null) {
        final placement = _computeInsertPlacement(
          baseWidth: 0.6,
          baseHeight: 0.1,
        );
        final block = Block(
          id: const Uuid().v4(),
          pageId: widget.page.id,
          type: BlockType.audio,
          x: placement.x,
          y: placement.y,
          width: placement.width,
          height: placement.height,
          zIndex: _blocks.length,
          payloadJson: AudioBlockPayload(
            path: path,
            durationMs: service.currentDuration.inMilliseconds,
          ).toJsonString(),
        );

        setState(() {
          _blocks.add(block);
          _isDirty = true;
        });

        _insertBlockWithSync(block);
        _uploadAndSyncAudioBlock(block, File(path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kayıt hatası: $e')));
      }
    }
  }

  void _showFramePicker() async {
    if (_selectedBlockId == null) return;

    final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
    final currentPayload = ImageBlockPayload.fromJson(block.payload);

    final style = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
          children: [
            const Text(
              'Çerçeve Seçin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FrameOption(
                    'Yok',
                    ImageFrameStyles.none,
                    Icons.crop_square,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Yuvarlak',
                    ImageFrameStyles.circle,
                    Icons.circle,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Köşeli',
                    ImageFrameStyles.rounded,
                    Icons.rounded_corner,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Polaroid',
                    ImageFrameStyles.polaroid,
                    Icons.photo,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Bant',
                    ImageFrameStyles.tape,
                    Icons.horizontal_rule,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Gölge',
                    ImageFrameStyles.shadow,
                    Icons.layers,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Film',
                    ImageFrameStyles.film,
                    Icons.movie,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Yığın',
                    ImageFrameStyles.stacked,
                    Icons.filter_none,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Etiket',
                    ImageFrameStyles.sticker,
                    Icons.label,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Kenarlık',
                    ImageFrameStyles.simpleBorder,
                    Icons.crop_free,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Gradyan',
                    ImageFrameStyles.gradient,
                    Icons.gradient,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Nostalji',
                    ImageFrameStyles.vintage,
                    Icons.history,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Katman',
                    ImageFrameStyles.layered,
                    Icons.layers_outlined,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Bant Köşe',
                    ImageFrameStyles.tapeCorners,
                    Icons.bookmark,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Polaroid Klasik',
                    ImageFrameStyles.polaroidClassic,
                    Icons.photo_size_select_actual,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Vintage Kenar',
                    ImageFrameStyles.vintageEdge,
                    Icons.photo_filter,
                    currentPayload.frameStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (style != null) {
      final newPayload = ImageBlockPayload(
        assetId: currentPayload.assetId,
        path: currentPayload.path,
        originalWidth: currentPayload.originalWidth,
        originalHeight: currentPayload.originalHeight,
        caption: currentPayload.caption,
        frameStyle: style,
        storagePath: currentPayload.storagePath,
      );

      await _updatePayloadWithSync(
        _selectedBlockId!,
        newPayload.toJsonString(),
      );

      // Sync update to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      // We need to fetch the updated block logic or just construct a minimal update
      // For MVP, simplistic:
      try {
        final updatedBlock = _blocks
            .firstWhere((b) => b.id == _selectedBlockId)
            .copyWith(payloadJson: newPayload.toJsonString());
        await firestoreService.updateBlock(
          updatedBlock,
          journalId: widget.page.journalId,
        );
      } catch (e) {
        /* ignore */
      }

      setState(() => _isDirty = true);
    }
  }

  void _deleteSelectedBlock() async {
    if (_selectedBlockId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloğu Sil'),
        content: const Text('Bu bloğu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(blockDaoProvider).softDelete(_selectedBlockId!);

      // Sync deletion to Firestore
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteBlock(
          _selectedBlockId!,
          journalId: widget.page.journalId,
          pageId: widget.page.id,
        );
      } catch (e) {
        debugPrint('Sync Delete Error: $e');
      }

      setState(() {
        _blocks.removeWhere((b) => b.id == _selectedBlockId);
        _selectedBlockId = null;
        _isDirty = true;
      });
    }
  }

  void _showRotateDialog() {
    if (_selectedBlockId == null) return;

    final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
    double newRotation = block.rotation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Resmi Döndür'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mevcut açı: ${newRotation.toInt()}°'),
                const SizedBox(height: 16),
                // Preview
                Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: newRotation * pi / 180,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _buildBlockContent(block, const Size(150, 150)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quick actions
                Wrap(
                  spacing: 8,
                  children: [0, 90, 180, 270].map((angle) {
                    return ElevatedButton(
                      onPressed: () {
                        setDialogState(() => newRotation = angle.toDouble());
                      },
                      child: Text('$angle°'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Slider
                Slider(
                  value: newRotation,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  label: '${newRotation.toInt()}°',
                  onChanged: (value) {
                    setDialogState(() => newRotation = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  _rotateImageBlock(newRotation);
                  Navigator.pop(context);
                },
                child: const Text('Uygula'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _rotateImageBlock(double angle) {
    if (_selectedBlockId == null) return;

    final index = _blocks.indexWhere((b) => b.id == _selectedBlockId);
    if (index == -1) return;

    setState(() {
      _blocks[index] = _blocks[index].copyWith(rotation: angle);
      _isDirty = true;
    });

    _updateBlockWithSync(_blocks[index]);
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydedilmemiş Değişiklikler'),
        content: const Text(
          'Kaydedilmemiş değişiklikleriniz var. Ne yapmak istersiniz?',
        ),
        actions: [
          // Exit without saving
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çık (Kaydetme)'),
          ),
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          // Save and Exit
          FilledButton(
            onPressed: () async {
              await _save();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Kaydet ve Çık'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

class _EraserPreviewPainter extends CustomPainter {
  final Offset point;
  final double radius;
  final Color color;

  const _EraserPreviewPainter({
    required this.point,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerStroke = Paint()
      ..color = (color == Colors.white ? Colors.black : Colors.white)
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(point, radius, outerStroke);
    canvas.drawCircle(point, radius, fill);
    canvas.drawCircle(point, radius, stroke);
  }

  @override
  bool shouldRepaint(covariant _EraserPreviewPainter oldDelegate) {
    return oldDelegate.point != point ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

enum EditorMode { select, text, draw, erase }

enum _HandleType { topLeft, topRight, bottomLeft, bottomRight, rotate }

enum _ScaleTarget { none, page, block }

class _BlockScaleSnapshot {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const _BlockScaleSnapshot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
  });

  factory _BlockScaleSnapshot.fromBlock(Block block) {
    return _BlockScaleSnapshot(
      x: block.x,
      y: block.y,
      width: block.width,
      height: block.height,
      rotation: block.rotation,
    );
  }
}

class _InsertPlacement {
  final double x;
  final double y;
  final double width;
  final double height;

  const _InsertPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolBtn(this.icon, this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withAlpha(30) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey[600],
              size: 20,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.deepPurple : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String currentValue;

  const _FrameOption(this.label, this.value, this.icon, this.currentValue);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withAlpha(20)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.deepPurple) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.deepPurple : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
