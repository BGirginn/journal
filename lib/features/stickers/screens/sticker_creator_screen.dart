import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/ui/drawing_board.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StickerCreatorScreen extends ConsumerStatefulWidget {
  const StickerCreatorScreen({super.key});

  @override
  ConsumerState<StickerCreatorScreen> createState() =>
      _StickerCreatorScreenState();
}

class _StickerCreatorScreenState extends ConsumerState<StickerCreatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _emojiController = TextEditingController();
  final DrawingController _drawingController = DrawingController();

  File? _selectedImage;
  Size _drawingCanvasSize = const Size(320, 320);
  String _selectedCategory = _stickerCategories.first.id;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emojiController.dispose();
    _drawingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String get _emojiInput => _emojiController.text.trim();

  bool get _canSave {
    if (_isSaving) return false;
    switch (_tabController.index) {
      case 0:
        return _selectedImage != null;
      case 1:
        return _emojiInput.isNotEmpty && _emojiInput.characters.length == 1;
      case 2:
        return !_drawingController.isEmpty;
      default:
        return false;
    }
  }

  Future<String> _copyImageToLocalStorage(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final stickersDir = Directory('${docsDir.path}/stickers');
    if (!await stickersDir.exists()) {
      await stickersDir.create(recursive: true);
    }
    final sourcePath = sourceFile.path;
    final dotIndex = sourcePath.lastIndexOf('.');
    final ext = dotIndex > -1 && dotIndex < sourcePath.length - 1
        ? sourcePath.substring(dotIndex)
        : '.png';
    final targetPath =
        '${stickersDir.path}/sticker_image_${const Uuid().v4()}$ext';
    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  Future<String> _saveDrawingToLocalStorage() async {
    final image = await _drawingController.toImage(_drawingCanvasSize);
    if (image == null) {
      throw Exception('Çizim kaydedilemedi');
    }
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Çizim verisi alınamadı');
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final stickersDir = Directory('${docsDir.path}/stickers');
    if (!await stickersDir.exists()) {
      await stickersDir.create(recursive: true);
    }
    final filePath =
        '${stickersDir.path}/sticker_drawing_${const Uuid().v4()}.png';
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _saveSticker() async {
    final tab = _tabController.index;
    if (tab == 0 && _selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Önce bir görsel seç')));
      return;
    }
    if (tab == 1 && _emojiInput.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emoji gir')));
      return;
    }
    if (tab == 1 && _emojiInput.characters.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tek bir emoji ya da sembol gir')),
      );
      return;
    }
    if (tab == 2 && _drawingController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydetmeden önce çizim yap')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final stickerService = ref.read(stickerServiceProvider);
      late StickerType type;
      late String content;
      String? localPath;

      if (tab == 0) {
        type = StickerType.image;
        localPath = await _copyImageToLocalStorage(_selectedImage!);
        content = localPath;
      } else if (tab == 1) {
        type = StickerType.emoji;
        content = _emojiInput;
      } else {
        type = StickerType.drawing;
        localPath = await _saveDrawingToLocalStorage();
        content = localPath;
      }

      await stickerService.createSticker(
        type: type,
        content: content,
        localPath: localPath,
        category: _selectedCategory,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Çıkartma kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Çıkartma'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resim', icon: Icon(LucideIcons.image)),
            Tab(text: 'Emoji', icon: Icon(LucideIcons.smile)),
            Tab(text: 'Çizim', icon: Icon(LucideIcons.brush)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: semantic.background,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stickerCategories
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category.label),
                      selected: _selectedCategory == category.id,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category.id;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ImageTab(
                  selectedImage: _selectedImage,
                  onPickImage: _pickImage,
                  onClearImage: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
                _EmojiTab(
                  controller: _emojiController,
                  onChanged: (_) => setState(() {}),
                  onSelectEmoji: (emoji) {
                    _emojiController.text = emoji;
                    _emojiController.selection = TextSelection.collapsed(
                      offset: emoji.length,
                    );
                    setState(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _drawingCanvasSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  radius.medium,
                                ),
                                border: Border.all(
                                  color: semantic.divider.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  radius.medium,
                                ),
                                child: DrawingBoard(
                                  controller: _drawingController,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _drawingController.clear();
                            setState(() {});
                          },
                          icon: const Icon(LucideIcons.trash2),
                          label: const Text('Temizle'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _canSave ? _saveSticker : null,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.check),
          label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _StickerCategory {
  final String id;
  final String label;

  const _StickerCategory({required this.id, required this.label});
}

const List<_StickerCategory> _stickerCategories = [
  _StickerCategory(id: 'duygular', label: 'Duygular'),
  _StickerCategory(id: 'favoriler', label: 'Favoriler'),
  _StickerCategory(id: 'ozel', label: 'Özel'),
  _StickerCategory(id: 'gokyuzu', label: 'Gökyüzü'),
  _StickerCategory(id: 'custom', label: 'Genel'),
];

class _ImageTab extends StatelessWidget {
  final File? selectedImage;
  final Future<void> Function() onPickImage;
  final VoidCallback onClearImage;

  const _ImageTab({
    required this.selectedImage,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: semantic.card,
                borderRadius: BorderRadius.circular(radius.large),
                border: Border.all(
                  color: semantic.divider.withValues(alpha: 0.8),
                ),
              ),
              child: selectedImage == null
                  ? Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(radius.large),
                      child: Image.file(selectedImage!, fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(LucideIcons.imagePlus),
                  label: const Text('Galeriden Seç'),
                ),
              ),
              if (selectedImage != null) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onClearImage,
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Temizle'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiTab extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelectEmoji;

  const _EmojiTab({
    required this.controller,
    required this.onChanged,
    required this.onSelectEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: semantic.card,
              borderRadius: BorderRadius.circular(radius.large),
              border: Border.all(
                color: semantic.divider.withValues(alpha: 0.8),
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 64),
              decoration: InputDecoration(
                hintText: '😀',
                counterText: '',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickEmojis
                .map(
                  (emoji) => OutlinedButton(
                    onPressed: () => onSelectEmoji(emoji),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

const List<String> _quickEmojis = [
  '😊',
  '😃',
  '😍',
  '😔',
  '🤔',
  '😎',
  '🥳',
  '❤️',
  '⭐',
  '🎉',
  '✨',
  '📚',
];
