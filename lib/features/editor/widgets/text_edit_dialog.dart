import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_app/core/models/block.dart';

class TextEditDialog extends StatefulWidget {
  final TextBlockPayload initialPayload;

  const TextEditDialog({super.key, required this.initialPayload});

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late TextEditingController _controller;
  late double _fontSize;
  late String _color;
  late String _fontFamily;
  late TextAlign _textAlign;

  final List<String> _fonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Oswald',
    'Raleway',
    'Merriweather',
    'Playfair Display',
    'Source Code Pro',
    'Pacifico',
    'Caveat',
    'Dancing Script',
  ];

  final List<Color> _colors = [
    Colors.black,
    Colors.grey[700]!,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow[700]!,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPayload.content);
    _fontSize = widget.initialPayload.fontSize;
    _color = widget.initialPayload.color;
    _fontFamily = widget.initialPayload.fontFamily == 'default'
        ? 'Roboto'
        : widget.initialPayload.fontFamily;
    _textAlign = _parseTextAlign(widget.initialPayload.textAlign);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextAlign _parseTextAlign(String? align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.black;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Metni Düzenle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Input
                    TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Metninizi buraya yazın...',
                      ),
                      style: GoogleFonts.getFont(
                        _fontFamily,
                        fontSize: 16,
                        color: _hexToColor(_color),
                      ),
                      textAlign: _textAlign,
                    ),
                    const SizedBox(height: 16),

                    // Font Family
                    const Text(
                      'Yazı Tipi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _fonts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final font = _fonts[index];
                          final isSelected = font == _fontFamily;
                          return ChoiceChip(
                            label: Text(font, style: GoogleFonts.getFont(font)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _fontFamily = font);
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alignment & Size
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hizalama',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<TextAlign>(
                                segments: const [
                                  ButtonSegment(
                                    value: TextAlign.left,
                                    icon: Icon(Icons.format_align_left),
                                  ),
                                  ButtonSegment(
                                    value: TextAlign.center,
                                    icon: Icon(Icons.format_align_center),
                                  ),
                                  ButtonSegment(
                                    value: TextAlign.right,
                                    icon: Icon(Icons.format_align_right),
                                  ),
                                ],
                                selected: {_textAlign},
                                onSelectionChanged:
                                    (Set<TextAlign> newSelection) {
                                      setState(
                                        () => _textAlign = newSelection.first,
                                      );
                                    },
                                style: const ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Boyut: ${_fontSize.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Slider(
                                value: _fontSize,
                                min: 10,
                                max: 72,
                                divisions: 62,
                                onChanged: (val) =>
                                    setState(() => _fontSize = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Colors
                    const Text(
                      'Renk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((color) {
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _color = _colorToHex(color)),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _color == _colorToHex(color)
                                    ? Colors.black
                                    : Colors.grey[300]!,
                                width: _color == _colorToHex(color) ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final newPayload = TextBlockPayload(
                  content: _controller.text,
                  fontSize: _fontSize,
                  color: _color,
                  fontFamily: _fontFamily,
                  textAlign: _textAlignToString(_textAlign),
                );
                Navigator.pop(context, newPayload);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
