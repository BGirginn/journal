import 'package:flutter/material.dart';

/// Sticker block type extension
enum StickerType { emoji, decorative, shape }

/// Sticker data
class Sticker {
  final String id;
  final String name;
  final String asset; // emoji character or asset path
  final StickerType type;
  final Color? color;

  const Sticker({
    required this.id,
    required this.name,
    required this.asset,
    required this.type,
    this.color,
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
    Sticker(id: 'leaf', name: 'Yaprak', asset: '🍃', type: StickerType.emoji),
    Sticker(
      id: 'butterfly',
      name: 'Kelebek',
      asset: '🦋',
      type: StickerType.emoji,
    ),
    Sticker(
      id: 'rainbow',
      name: 'Gökkuşağı',
      asset: '🌈',
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
    Sticker(id: 'plus', name: 'Artı', asset: '+', type: StickerType.decorative),
    Sticker(
      id: 'minus',
      name: 'Eksi',
      asset: '−',
      type: StickerType.decorative,
    ),
    Sticker(
      id: 'bullet',
      name: 'Madde',
      asset: '•',
      type: StickerType.decorative,
    ),
    Sticker(
      id: 'diamond',
      name: 'Elmas',
      asset: '◆',
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

  static List<Sticker> get all => [...emojis, ...decoratives, ...shapes];
}

/// Sticker picker widget
class StickerPicker extends StatelessWidget {
  final void Function(Sticker) onSelect;

  const StickerPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sticker Seç',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
        child: Center(
          child: Text(
            sticker.asset,
            style: TextStyle(
              fontSize: sticker.type == StickerType.emoji ? 24 : 20,
              color: sticker.color,
            ),
          ),
        ),
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
