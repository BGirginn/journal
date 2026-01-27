import 'dart:io';
import 'dart:ui' as import_ui; // Added for ImageByteFormat
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/core/ui/drawing_board.dart';
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
  final TextEditingController _emojiController = TextEditingController();
  final DrawingController _drawingController = DrawingController();

  File? _selectedImage;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emojiController.dispose();
    _drawingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveSticker() async {
    setState(() => _isSaving = true);
    try {
      final stickerService = ref.read(stickerServiceProvider);

      StickerType type;
      String content;
      String? localPath;

      switch (_tabController.index) {
        case 0: // Image
          if (_selectedImage == null) throw Exception('Resim seçilmedi');
          type = StickerType.image;
          localPath = _selectedImage!.path;
          content =
              'temp_path'; // Ideally upload to Firebase Storage and get URL
          // For now, let's assume we use local path or handle upload inside service (not implemented there yet)
          // We will store local path as content for now if offline, but service should ideally upload.
          // Let's pass local path content and handle storage later or now?
          // Phase 3 plan says: "Remote (Firestore): Sync... Storage (Firebase): Store valid image assets."
          // I didn't implement Storage upload in Service yet.
          content = _selectedImage!.path; // Temporary placeholders
          break;
        case 1: // Emoji
          final text = _emojiController.text;
          if (text.isEmpty) throw Exception('Emoji girilmedi');
          type = StickerType.emoji;
          content = text;
          break;
        case 2: // Drawing
          if (_drawingController.isEmpty) throw Exception('Çizim yapılmadı');
          type = StickerType.drawing;

          // Save drawing to file
          final image = await _drawingController.toImage(
            const Size(300, 300),
          ); // Fixed size for now or dynamic?
          if (image == null) throw Exception('Çizim kaydedilemedi');

          final byteData = await image.toByteData(
            format: import_ui.ImageByteFormat.png,
          );
          if (byteData == null) throw Exception('Görüntü verisi alınamadı');

          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'sticker_drawing_${const Uuid().v4()}.png';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(byteData.buffer.asUint8List());

          localPath = file.path;
          content = file.path;
          break;
        default:
          throw Exception('Bilinmeyen mod');
      }

      await stickerService.createSticker(
        type: type,
        content: content,
        localPath: localPath,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Çıkartma kaydedildi')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Çıkartma'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resim', icon: Icon(Icons.image)),
            Tab(text: 'Emoji', icon: Icon(Icons.emoji_emotions)),
            Tab(text: 'Çizim', icon: Icon(Icons.brush)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to avoid gesture conflict with drawing
        children: [
          // Image Tab
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 200)
              else
                const Icon(Icons.image, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Galeriden Seç'),
              ),
            ],
          ),
          // Emoji Tab
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: TextField(
                controller: _emojiController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 80),
                decoration: const InputDecoration(
                  hintText: '😀',
                  border: InputBorder.none,
                ),
                maxLength: 1, // Only 1 emoji
              ),
            ),
          ),
          // Drawing Tab
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                  ),
                  child: DrawingBoard(controller: _drawingController),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0), // Space for FAB
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _drawingController.clear,
                      tooltip: 'Temizle',
                    ),
                    // Add simple color picker later if needed
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSticker,
        label: _isSaving
            ? const CircularProgressIndicator()
            : const Text('Kaydet'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
