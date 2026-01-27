import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';
import 'dart:io';

class StickerManagerScreen extends ConsumerWidget {
  const StickerManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerService = ref.watch(stickerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çıkartmalarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/stickers/create'),
          ),
        ],
      ),
      body: StreamBuilder<List<UserSticker>>(
        stream: stickerService.watchMyStickers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stickers = snapshot.data ?? [];

          if (stickers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Henüz çıkartma yok.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/stickers/create'),
                    child: const Text('Çıkartma Oluştur'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return _StickerItem(
                sticker: sticker,
                onDelete: () {
                  stickerService.deleteSticker(sticker.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StickerItem extends StatelessWidget {
  final UserSticker sticker;
  final VoidCallback onDelete;

  const _StickerItem({required this.sticker, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (sticker.type) {
      case StickerType.image:
      case StickerType.drawing:
        // Try local path first
        if (sticker.localPath != null &&
            File(sticker.localPath!).existsSync()) {
          content = Image.file(File(sticker.localPath!), fit: BoxFit.contain);
        } else {
          // If remote URL is in content (future), use network.
          // For now, if local missing, show error or placeholder
          content = const Icon(Icons.broken_image);
        }
        break;
      case StickerType.emoji:
        content = Center(
          child: Text(sticker.content, style: const TextStyle(fontSize: 40)),
        );
        break;
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
