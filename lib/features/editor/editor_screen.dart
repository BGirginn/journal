import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/features/editor/widgets/image_picker_service.dart';
import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';
import 'package:journal_app/features/editor/widgets/audio_block_widget.dart';
import 'package:journal_app/features/editor/services/audio_recorder_service.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/core/database/firestore_service.dart';

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

  // Editor state
  EditorMode _mode = EditorMode.select;
  String? _selectedBlockId;
  Color _penColor = Colors.black;
  double _penWidth = 2.0;

  // Transform state
  Offset? _dragStart;
  Offset? _originalPosition;
  _HandleType? _activeHandle;

  @override
  void initState() {
    super.initState();
    _theme = NostalgicThemes.getById(widget.journal.coverStyle);
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Load blocks
    final blockDao = ref.read(blockDaoProvider);
    blockDao.watchBlocksForPage(widget.page.id).listen((blocks) {
      if (mounted) {
        setState(() {
          _blocks = blocks;
          _isLoading = false;
        });
      }
    });

    // Load ink strokes from page
    final pageDao = ref.read(pageDaoProvider);
    final page = await pageDao.getPageById(widget.page.id);
    if (page != null && page.inkData.isNotEmpty) {
      setState(() {
        _strokes = InkStrokeData.decodeStrokes(page.inkData);
      });
    }
  }

  Future<void> _save() async {
    // Save ink strokes to page
    final pageDao = ref.read(pageDaoProvider);
    final inkJson = InkStrokeData.encodeStrokes(_strokes);
    await pageDao.updateInkData(widget.page.id, inkJson);

    // Save blocks
    final blockDao = ref.read(blockDaoProvider);
    for (final block in _blocks) {
      await blockDao.updateBlock(block);
    }

    // Sync to Firestore
    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Sync Page (Ink Data)
      // We need to construct the updated page object
      final updatedPage = widget.page.copyWith(
        inkData: inkJson,
        updatedAt: DateTime.now(),
      );
      await firestoreService.updatePage(updatedPage);

      // Sync Blocks
      for (final block in _blocks) {
        await firestoreService.createBlock(
          block,
        ); // createBlock uses set() (upsert)
      }
    } catch (e) {
      debugPrint('Firestore Save Error: $e');
    }

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

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.id == 'midnight';

    return Scaffold(
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
            if (_isDirty) await _save();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        actions: [
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
                if (_mode == EditorMode.draw) _buildPenOptions(),
                Expanded(child: _buildCanvas()),
              ],
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
            () => setState(() => _mode = EditorMode.select),
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
            () => setState(() => _mode = EditorMode.draw),
          ),
          _ToolBtn(Icons.image, 'Resim', false, _addImage),
          _ToolBtn(Icons.mic, 'Ses', false, _recordAudio),
          if (_selectedBlockId != null) ...[
            if (_getSelectedBlockType() == BlockType.image)
              _ToolBtn(Icons.style, 'Çerçeve', false, _showFramePicker),
            _ToolBtn(Icons.delete, 'Sil', false, _deleteSelectedBlock),
          ],
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Colors
          ...[Colors.black, Colors.blue, Colors.red, Colors.green].map(
            (c) => GestureDetector(
              onTap: () => setState(() => _penColor = c),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _penColor == c
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: _penColor == c
                      ? [BoxShadow(color: c, blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ),
          const VerticalDivider(),
          // Widths
          ...[2.0, 4.0, 8.0].map(
            (w) => GestureDetector(
              onTap: () => setState(() => _penWidth = w),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _penWidth == w
                      ? Colors.deepPurple.withAlpha(30)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Container(
                    width: w * 2,
                    height: w * 2,
                    decoration: BoxDecoration(
                      color: _penColor,
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
            icon: const Icon(Icons.delete_outline),
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

        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, pageSize),
          onPanUpdate: (d) => _onPanUpdate(d, pageSize),
          onPanEnd: (d) => _onPanEnd(),
          onTapUp: (d) => _onTapUp(d, pageSize),
          child: Container(
            margin: const EdgeInsets.all(12),
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
                  CustomPaint(
                    painter: NostalgicPagePainter(theme: _theme),
                    size: Size.infinite,
                  ),

                  // Ink strokes
                  CustomPaint(
                    painter: OptimizedInkPainter(
                      strokes: _strokes,
                      currentStroke: null,
                    ),
                    size: Size.infinite,
                  ),

                  // Blocks
                  ..._blocks.map((block) => _buildBlock(block, pageSize)),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                Positioned.fill(child: _buildBlockContent(block)),

                // Selection handles
                if (isSelected) ...[
                  // Corner handles for resize
                  _buildHandle(block, _HandleType.topLeft, -6, -6, null, null),
                  _buildHandle(block, _HandleType.topRight, null, -6, -6, null),
                  _buildHandle(
                    block,
                    _HandleType.bottomLeft,
                    -6,
                    null,
                    null,
                    -6,
                  ),
                  _buildHandle(
                    block,
                    _HandleType.bottomRight,
                    null,
                    null,
                    -6,
                    -6,
                  ),
                  // Rotate handle
                  Positioned(
                    left: width / 2 - 10,
                    top: -30,
                    child: GestureDetector(
                      onPanStart: (_) {
                        _activeHandle = _HandleType.rotate;
                      },
                      onPanUpdate: (d) => _onRotate(block, d, pageSize),
                      onPanEnd: (_) => _activeHandle = null,
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
  ) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanStart: (d) {
          _activeHandle = type;
          _originalPosition = Offset(block.x, block.y);
        },
        onPanUpdate: (d) => _onResize(block, d, type),
        onPanEnd: (_) => _activeHandle = null,
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
    );
  }

  Widget _buildBlockContent(Block block) {
    switch (block.type) {
      case BlockType.text:
        final payload = TextBlockPayload.fromJson(block.payload);
        final isDark = _theme.id == 'midnight';
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
      case BlockType.image:
        final payload = ImageBlockPayload.fromJson(block.payload);
        if (payload.path != null && File(payload.path!).existsSync()) {
          return ImageFrameWidget(
            path: payload.path!,
            frameStyle: payload.frameStyle,
            width: block.width * MediaQuery.of(context).size.width,
            height: block.height * MediaQuery.of(context).size.height,
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

  void _onTapUp(TapUpDetails details, Size pageSize) {
    if (_mode == EditorMode.select) {
      // Deselect if tapping empty area
      setState(() => _selectedBlockId = null);
    }
  }

  void _onPanStart(DragStartDetails details, Size pageSize) {
    if (_mode == EditorMode.draw) {
      // Start new stroke
      final point = details.localPosition;
      setState(() {
        _strokes = [
          ..._strokes,
          InkStrokeData(
            points: [point],
            colorValue: _penColor.toARGB32(),
            width: _penWidth,
          ),
        ];
        _isDirty = true;
      });
    } else if (_mode == EditorMode.select && _selectedBlockId != null) {
      // Start dragging selected block
      _dragStart = details.localPosition;
      final block = _blocks.firstWhere((b) => b.id == _selectedBlockId);
      _originalPosition = Offset(block.x, block.y);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size pageSize) {
    if (_mode == EditorMode.draw && _strokes.isNotEmpty) {
      // Continue stroke
      final point = details.localPosition;
      setState(() {
        final lastStroke = _strokes.last;
        _strokes = [
          ..._strokes.sublist(0, _strokes.length - 1),
          InkStrokeData(
            points: [...lastStroke.points, point],
            colorValue: lastStroke.colorValue,
            width: lastStroke.width,
          ),
        ];
      });
    } else if (_mode == EditorMode.select &&
        _selectedBlockId != null &&
        _dragStart != null &&
        _activeHandle == null) {
      // Move block
      final delta = details.localPosition - _dragStart!;
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
  }

  void _onResize(Block block, DragUpdateDetails details, _HandleType type) {
    final delta = Offset(
      details.delta.dx / 300,
      details.delta.dy / 300,
    ); // Normalized

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
    final block = Block(
      pageId: widget.page.id,
      type: BlockType.text,
      x: 0.1,
      y: 0.2,
      width: 0.4,
      height: 0.08,
      zIndex: _blocks.length,
      payloadJson: TextBlockPayload(content: '').toJsonString(),
    );

    await ref.read(blockDaoProvider).insertBlock(block);
    setState(() => _isDirty = true);
  }

  void _addImage() async {
    final file = await showImageSourcePicker(context);
    if (file == null) return;

    final block = Block(
      pageId: widget.page.id,
      type: BlockType.image,
      x: 0.1,
      y: 0.3,
      width: 0.35,
      height: 0.25,
      zIndex: _blocks.length,
      payloadJson: ImageBlockPayload(
        assetId: null,
        path: file.path,
      ).toJsonString(),
    );

    await ref.read(blockDaoProvider).insertBlock(block);

    // Upload to Firebase Storage & Sync Database
    _uploadAndSyncBlock(block, file);

    setState(() => _isDirty = true);
  }

  Future<void> _uploadAndSyncBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final blockDao = ref.read(blockDaoProvider);

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
        await blockDao.updatePayload(block.id, newPayload.toJsonString());

        // Update valid block reference for Firestore sync
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      // 3. Sync Block Metadata to Firestore
      await firestoreService.createBlock(block);
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> _uploadAndSyncAudioBlock(Block block, File file) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final blockDao = ref.read(blockDaoProvider);

      final storagePath = await storageService.uploadFile(file);

      if (storagePath != null) {
        final currentPayload = AudioBlockPayload.fromJson(block.payload);
        final newPayload = AudioBlockPayload(
          assetId: currentPayload.assetId,
          path: currentPayload.path,
          durationMs: currentPayload.durationMs,
          storagePath: storagePath,
        );

        await blockDao.updatePayload(block.id, newPayload.toJsonString());
        block = block.copyWith(payloadJson: newPayload.toJsonString());
      }

      await firestoreService.createBlock(block);
    } catch (e) {
      debugPrint('Audio Sync Error: $e');
    }
  }

  void _recordAudio() async {
    final service = AudioRecorderService();

    // Simple recording dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ses Kaydediliyor...'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 48, color: Colors.red),
                SizedBox(height: 16),
                LinearProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final path = await service.stopRecording();
                  if (context.mounted) Navigator.pop(context, path);
                },
                child: const Text('Durdur ve Kaydet'),
              ),
            ],
          );
        },
      ),
    ).then((path) async {
      await service.dispose();
      if (path != null) {
        final block = Block(
          pageId: widget.page.id,
          type: BlockType.audio,
          x: 0.1,
          y: 0.4,
          width: 0.6,
          height: 0.1, // Fixed height for audio player
          zIndex: _blocks.length,
          payloadJson: AudioBlockPayload(
            path: path,
            durationMs: 0, // Should get real duration
          ).toJsonString(),
        );

        await ref.read(blockDaoProvider).insertBlock(block);

        // Upload Audio & Sync
        _uploadAndSyncAudioBlock(block, File(path));

        setState(() => _isDirty = true);
      }
    });

    try {
      await service.startRecording();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
                    'none',
                    Icons.crop_square,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Polaroid',
                    'polaroid',
                    Icons.photo,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Bant',
                    'tape',
                    Icons.horizontal_rule,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Gölge',
                    'shadow',
                    Icons.layers,
                    currentPayload.frameStyle,
                  ),
                  _FrameOption(
                    'Kenarlık',
                    'simple_border',
                    Icons.crop_free,
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
      );

      await ref
          .read(blockDaoProvider)
          .updatePayload(_selectedBlockId!, newPayload.toJsonString());

      // Sync update to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      // We need to fetch the updated block logic or just construct a minimal update
      // For MVP, simplistic:
      try {
        final updatedBlock = _blocks
            .firstWhere((b) => b.id == _selectedBlockId)
            .copyWith(payloadJson: newPayload.toJsonString());
        await firestoreService.createBlock(
          updatedBlock,
        ); // createBlock uses set (upsert)
      } catch (e) {
        /* ignore */
      }

      setState(() => _isDirty = true);
    }
  }

  void _deleteSelectedBlock() async {
    if (_selectedBlockId == null) return;

    await ref.read(blockDaoProvider).softDelete(_selectedBlockId!);

    // Sync deletion to Firestore
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteBlock(_selectedBlockId!);
    } catch (e) {
      debugPrint('Firestore Block Delete Error: $e');
    }

    setState(() {
      _selectedBlockId = null;
      _isDirty = true;
    });
  }
}

enum EditorMode { select, text, draw }

enum _HandleType { topLeft, topRight, bottomLeft, bottomRight, rotate }

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
