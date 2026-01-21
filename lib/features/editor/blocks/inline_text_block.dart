import 'dart:math';
import 'package:flutter/material.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/journal_theme.dart';

/// Inline text block - writes directly on the page without box
class InlineTextBlock extends StatefulWidget {
  final Block block;
  final Size pageSize;
  final bool isSelected;
  final bool isEditing;
  final JournalTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onEditComplete;
  final void Function(String) onTextChanged;

  const InlineTextBlock({
    super.key,
    required this.block,
    required this.pageSize,
    required this.isSelected,
    required this.isEditing,
    required this.theme,
    required this.onTextChanged,
    this.onTap,
    this.onEditComplete,
  });

  @override
  State<InlineTextBlock> createState() => _InlineTextBlockState();
}

class _InlineTextBlockState extends State<InlineTextBlock> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final payload = TextBlockPayload.fromJson(widget.block.payload);
    _controller = TextEditingController(text: payload.content);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.isEditing) {
        widget.onEditComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InlineTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.block.x * widget.pageSize.width;
    final top = widget.block.y * widget.pageSize.height;
    final width = widget.block.width * widget.pageSize.width;
    final height = widget.block.height * widget.pageSize.height;

    final payload = TextBlockPayload.fromJson(widget.block.payload);
    final isDark = widget.theme.id == 'dark';
    final textColor = isDark ? Colors.white : Colors.black87;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.rotate(
          angle: widget.block.rotation * pi / 180,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Content
                Positioned.fill(
                  child: widget.isEditing
                      ? _buildEditableText(textColor, payload)
                      : _buildDisplayText(textColor, payload),
                ),
                // Selection indicator
                if (widget.isSelected && !widget.isEditing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.deepPurple.withAlpha(100),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayText(Color textColor, TextBlockPayload payload) {
    if (payload.content.isEmpty || payload.content == 'Metin yazın...') {
      return const SizedBox.shrink();
    }

    return Text(
      payload.content,
      style: TextStyle(
        fontSize: payload.fontSize,
        color: textColor,
        fontFamily: _getFontFamily(),
        height: 1.5,
      ),
    );
  }

  Widget _buildEditableText(Color textColor, TextBlockPayload payload) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      style: TextStyle(
        fontSize: payload.fontSize,
        color: textColor,
        fontFamily: _getFontFamily(),
        height: 1.5,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged: widget.onTextChanged,
    );
  }

  String _getFontFamily() {
    switch (widget.theme.defaultFont) {
      case 'serif':
        return 'Georgia';
      case 'handwritten':
        return 'Caveat';
      default:
        return 'Roboto';
    }
  }
}
