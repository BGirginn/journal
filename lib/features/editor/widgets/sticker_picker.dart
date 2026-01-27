import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/models/user_sticker.dart' as model;
import 'package:journal_app/features/stickers/sticker_service.dart';

/// Sticker block type extension
enum StickerType { emoji, decorative, shape, custom }

/// Sticker data
class Sticker {
  final String id;
  final String name;
  final String asset; // emoji character or asset path
  final StickerType type;
  final Color? color;
  final bool isCustom;

  const Sticker({
    required this.id,
    required this.name,
    required this.asset,
    required this.type,
    this.color,
    this.isCustom = false,
  });
}

/// Built-in stickers
class BuiltInStickers {
  static const List<Sticker> emojis = [
    Sticker(id: 'heart', name: 'Kalp', asset: '❤️', type: StickerType.emoji),
    Sticker(id: 'star', name: 'Yıldız', asset: '⭐', type: StickerType.emoji),
    Sticker(id: 'sun', name: 'Güneş', asset: '☀️', type: StickerType.emoji),
    Sticker(id: 'moon', name: 'Ay', asset: '🌙', type: StickerType.emoji),
    Sticker(id: 'flower', name: 'Çiçek', asset: '🌸', type: StickerType.emoji),
    Sticker(
      id: 'butterfly',
      name: 'Kelebek',
      asset: '🦋',
      type: StickerType.emoji,
    ),
    Sticker(id: 'sparkle', name: 'Işıltı', asset: '✨', type: StickerType.emoji),
    Sticker(id: 'fire', name: 'Ateş', asset: '🔥', type: StickerType.emoji),
    Sticker(id: 'cloud', name: 'Bulut', asset: '☁️', type: StickerType.emoji),
    Sticker(
      id: 'lightning',
      name: 'Şimşek',
      asset: '⚡',
      type: StickerType.emoji,
    ),
  ];

  static const List<Sticker> decoratives = [
    Sticker(
      id: 'arrow_right',
      name: 'Ok Sağ',
      asset: '→',
      type: StickerType.decorative,
    ),
    Sticker(
      id: 'arrow_left',
      name: 'Ok Sol',
      asset: '←',
      type: StickerType.decorative,
    ),
    Sticker(id: 'check', name: 'Tik', asset: '✓', type: StickerType.decorative),
    Sticker(
      id: 'cross',
      name: 'Çarpı',
      asset: '✗',
      type: StickerType.decorative,
    ),
    Sticker(
      id: 'bullet',
      name: 'Madde',
      asset: '•',
      type: StickerType.decorative,
    ),
  ];

  static const List<Sticker> shapes = [
    Sticker(
      id: 'circle',
      name: 'Daire',
      asset: '●',
      type: StickerType.shape,
      color: Colors.red,
    ),
    Sticker(
      id: 'square',
      name: 'Kare',
      asset: '■',
      type: StickerType.shape,
      color: Colors.blue,
    ),
    Sticker(
      id: 'triangle',
      name: 'Üçgen',
      asset: '▲',
      type: StickerType.shape,
      color: Colors.green,
    ),
    Sticker(
      id: 'star_shape',
      name: 'Yıldız',
      asset: '★',
      type: StickerType.shape,
      color: Colors.amber,
    ),
  ];
}

/// Sticker picker widget
class StickerPicker extends ConsumerWidget {
  final void Function(Sticker) onSelect;

  const StickerPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerService = ref.watch(stickerServiceProvider);

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sticker Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  context.push('/stickers/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Stickers Section
                  StreamBuilder<List<model.UserSticker>>(
                    stream: stickerService.watchMyStickers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final customStickers = snapshot.data!.map((s) {
                        String asset = s.content;
                        // Map UserSticker type to Picker StickerType
                        StickerType pickerType = StickerType.emoji;

                        if (s.type == model.StickerType.image ||
                            s.type == model.StickerType.drawing) {
                          pickerType = StickerType.custom;
                          if (s.localPath != null &&
                              File(s.localPath!).existsSync()) {
                            asset = s.localPath!;
                          }
                        } else {
                          // Emoji
                          pickerType = StickerType.emoji;
                        }

                        return Sticker(
                          id: s.id,
                          name: 'Custom',
                          asset: asset,
                          type: pickerType,
                          isCustom:
                              s.type == model.StickerType.image ||
                              s.type == model.StickerType.drawing,
                        );
                      }).toList();

                      return _buildSection(
                        'Özel Çıkartmalarım',
                        customStickers,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSection('Emojiler', BuiltInStickers.emojis),
                  const SizedBox(height: 12),
                  _buildSection('Dekoratif', BuiltInStickers.decoratives),
                  const SizedBox(height: 12),
                  _buildSection('Şekiller', BuiltInStickers.shapes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Sticker> stickers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stickers
              .map(
                (sticker) => _StickerItem(
                  sticker: sticker,
                  onTap: () => onSelect(sticker),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StickerItem extends StatelessWidget {
  final Sticker sticker;
  final VoidCallback onTap;

  const _StickerItem({required this.sticker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (sticker.isCustom && File(sticker.asset).existsSync()) {
      // It's likely an image path
      content = Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.file(File(sticker.asset), fit: BoxFit.contain),
      );
    } else {
      // Emoji/Text
      content = Center(
        child: Text(
          sticker.asset,
          style: TextStyle(
            fontSize: sticker.type == StickerType.emoji ? 24 : 20,
            color: sticker.color,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: content,
      ),
    );
  }
}

/// Show sticker picker bottom sheet
Future<Sticker?> showStickerPicker(BuildContext context) async {
  Sticker? result;
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => StickerPicker(
      onSelect: (sticker) {
        result = sticker;
        Navigator.pop(context);
      },
    ),
  );
  return result;
}
