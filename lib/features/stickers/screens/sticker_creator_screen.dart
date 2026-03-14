import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
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

class _StickerCreatorScreenState extends ConsumerState<StickerCreatorScreen> {
  final ImagePicker _picker = ImagePicker();
  final TransformationController _cropController = TransformationController();
  final GlobalKey _cropBoundaryKey = GlobalKey();

  File? _selectedImage;
  Uint8List? _backgroundRemovedImageBytes;
  String _selectedCategory = _stickerCategories.first.id;
  bool _isSaving = false;
  bool _isRemovingBackground = false;
  bool _isBgEngineReady = false;
  String? _bgInitError;

  bool get _canSave => !_isSaving && _selectedImage != null;

  @override
  void initState() {
    super.initState();
    _initBackgroundRemover();
  }

  @override
  void dispose() {
    unawaited(BackgroundRemover.instance.dispose());
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _initBackgroundRemover() async {
    try {
      await BackgroundRemover.instance.initializeOrt();
      if (!mounted) {
        return;
      }
      setState(() {
        _isBgEngineReady = true;
        _bgInitError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBgEngineReady = false;
        _bgInitError = e.toString();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 95,
    );
    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      _selectedImage = File(pickedFile.path);
      _backgroundRemovedImageBytes = null;
      _cropController.value = Matrix4.identity();
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _backgroundRemovedImageBytes = null;
      _cropController.value = Matrix4.identity();
    });
  }

  void _resetCrop() {
    setState(() {
      _cropController.value = Matrix4.identity();
    });
  }

  Future<void> _removeBackground() async {
    final imageFile = _selectedImage;
    if (imageFile == null) {
      return;
    }
    if (!_isBgEngineReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arka plan kaldırma motoru hazır değil.')),
      );
      return;
    }

    setState(() => _isRemovingBackground = true);
    try {
      final imageBytes = await imageFile.readAsBytes();
      final removedBytes = await BackgroundRemover.instance.removeBgBytes(
        imageBytes,
        threshold: 0.35,
        smoothMask: true,
        enhanceEdges: true,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _backgroundRemovedImageBytes = removedBytes;
        _cropController.value = Matrix4.identity();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Arka plan kaldırılamadı: $e')));
    } finally {
      if (mounted) {
        setState(() => _isRemovingBackground = false);
      }
    }
  }

  void _restoreOriginalImage() {
    setState(() {
      _backgroundRemovedImageBytes = null;
      _cropController.value = Matrix4.identity();
    });
  }

  ImageProvider<Object>? _activeImageProvider() {
    final removed = _backgroundRemovedImageBytes;
    if (removed != null) {
      return MemoryImage(removed);
    }
    final selected = _selectedImage;
    if (selected != null) {
      return FileImage(selected);
    }
    return null;
  }

  Future<String> _exportCroppedStickerToLocalStorage() async {
    final boundaryContext = _cropBoundaryKey.currentContext;
    final boundary =
        boundaryContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Sticker önizlemesi hazır değil.');
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final pixelRatio = dpr.clamp(1.0, 3.0);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Sticker görseli oluşturulamadı.');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final stickersDir = Directory('${docsDir.path}/stickers');
    if (!await stickersDir.exists()) {
      await stickersDir.create(recursive: true);
    }

    final filePath =
        '${stickersDir.path}/sticker_image_${const Uuid().v4()}.png';
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _saveSticker() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Önce bir görsel seçin.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final localPath = await _exportCroppedStickerToLocalStorage();

      await ref
          .read(stickerServiceProvider)
          .createSticker(
            type: StickerType.image,
            content: localPath,
            localPath: localPath,
            category: _selectedCategory,
          );

      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Çıkartma kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sticker kaydedilemedi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);

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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final stageSide = (constraints.maxWidth - 32)
              .clamp(220.0, 460.0)
              .toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: semantic.background,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
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
                const SizedBox(height: 12),
                Center(
                  child: _ImageCropStage(
                    side: stageSide,
                    imageProvider: _activeImageProvider(),
                    transformationController: _cropController,
                    repaintBoundaryKey: _cropBoundaryKey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'WhatsApp benzeri kullanım: görseli seç, iki parmakla yakınlaştır/uzaklaştır ve sürükleyerek konumlandır.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(LucideIcons.imagePlus),
                        label: const Text('Galeri'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(LucideIcons.camera),
                        label: const Text('Kamera'),
                      ),
                    ),
                  ],
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isRemovingBackground
                              ? null
                              : (_isBgEngineReady ? _removeBackground : null),
                          icon: _isRemovingBackground
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(LucideIcons.scissors),
                          label: Text(
                            _isRemovingBackground
                                ? 'Arka Plan Kaldırılıyor...'
                                : 'Arka Planı Kaldır',
                          ),
                        ),
                      ),
                      if (_backgroundRemovedImageBytes != null) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _restoreOriginalImage,
                          child: const Text('Orijinale Dön'),
                        ),
                      ],
                    ],
                  ),
                ],
                if (_bgInitError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Arka plan kaldırma şu anda devre dışı: $_bgInitError',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_selectedImage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetCrop,
                        icon: const Icon(LucideIcons.rotateCcw),
                        label: const Text('Kırpmayı Sıfırla'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(LucideIcons.trash2),
                        label: const Text('Temizle'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
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
          label: Text(_isSaving ? 'Kaydediliyor...' : 'Sticker Olarak Kaydet'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _ImageCropStage extends StatelessWidget {
  final double side;
  final ImageProvider<Object>? imageProvider;
  final TransformationController transformationController;
  final GlobalKey repaintBoundaryKey;

  const _ImageCropStage({
    required this.side,
    required this.imageProvider,
    required this.transformationController,
    required this.repaintBoundaryKey,
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

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: semantic.card,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius.large),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (imageProvider != null)
              RepaintBoundary(
                key: repaintBoundaryKey,
                child: InteractiveViewer(
                  transformationController: transformationController,
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Image(image: imageProvider!, fit: BoxFit.cover),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.image,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sticker için görsel seç',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            if (imageProvider != null)
              const IgnorePointer(child: _CropGridOverlay()),
          ],
        ),
      ),
    );
  }
}

class _CropGridOverlay extends StatelessWidget {
  const _CropGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(color: Colors.white.withValues(alpha: 0.35)),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final hThird = size.height / 3;
    final wThird = size.width / 3;

    canvas.drawLine(Offset(wThird, 0), Offset(wThird, size.height), paint);
    canvas.drawLine(
      Offset(wThird * 2, 0),
      Offset(wThird * 2, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, hThird), Offset(size.width, hThird), paint);
    canvas.drawLine(
      Offset(0, hThird * 2),
      Offset(size.width, hThird * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
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
