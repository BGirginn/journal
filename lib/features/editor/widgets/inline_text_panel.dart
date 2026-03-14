import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_app/core/models/block.dart';

/// Compact inline text editing panel that replaces the old modal TextEditDialog.
/// Renders as a sliding panel at the bottom of the editor canvas.
class InlineTextPanel extends StatefulWidget {
  final TextBlockPayload initialPayload;
  final ValueChanged<TextBlockPayload> onChanged;
  final VoidCallback onClose;

  const InlineTextPanel({
    super.key,
    required this.initialPayload,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<InlineTextPanel> createState() => _InlineTextPanelState();
}

class _InlineTextPanelState extends State<InlineTextPanel> {
  late TextEditingController _controller;
  late double _fontSize;
  late String _color;
  late String _fontFamily;
  late TextAlign _textAlign;

  static const _fonts = [
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

  static const _colors = <Color>[
    Colors.black,
    Color(0xFF616161), // grey 700
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
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
    _controller.addListener(_emitChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_emitChange);
    _controller.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(TextBlockPayload(
      content: _controller.text,
      fontSize: _fontSize,
      color: _color,
      fontFamily: _fontFamily,
      textAlign: _textAlignToString(_textAlign),
    ));
  }

  TextAlign _parseTextAlign(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
        return 'right';
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
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 12,
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle + close
              Row(
                children: [
                  const SizedBox(width: 40),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check_circle, size: 28),
                    color: colorScheme.primary,
                    onPressed: widget.onClose,
                    tooltip: 'Kapat',
                  ),
                ],
              ),

              // Text input
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Metin yaz...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.getFont(
                  _fontFamily,
                  fontSize: 15,
                  color: _hexToColor(_color),
                ),
                textAlign: _textAlign,
              ),
              const SizedBox(height: 8),

              // Controls row 1: alignment + size
              Row(
                children: [
                  // Alignment
                  SegmentedButton<TextAlign>(
                    segments: const [
                      ButtonSegment(
                        value: TextAlign.left,
                        icon: Icon(Icons.format_align_left, size: 18),
                      ),
                      ButtonSegment(
                        value: TextAlign.center,
                        icon: Icon(Icons.format_align_center, size: 18),
                      ),
                      ButtonSegment(
                        value: TextAlign.right,
                        icon: Icon(Icons.format_align_right, size: 18),
                      ),
                    ],
                    selected: {_textAlign},
                    onSelectionChanged: (s) {
                      setState(() => _textAlign = s.first);
                      _emitChange();
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Font size
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${_fontSize.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 10,
                            max: 72,
                            divisions: 62,
                            onChanged: (val) {
                              setState(() => _fontSize = val);
                              _emitChange();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Controls row 2: font family chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fonts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final font = _fonts[index];
                    final isSelected = font == _fontFamily;
                    return ChoiceChip(
                      label: Text(
                        font,
                        style: GoogleFonts.getFont(font, fontSize: 11),
                      ),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _fontFamily = font);
                          _emitChange();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Controls row 3: color dots
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final c = _colors[index];
                    final hex = _colorToHex(c);
                    final isSelected = _color == hex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _color = hex);
                        _emitChange();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? colorScheme.primary : Colors.grey,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
