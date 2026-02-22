import 'package:flutter/material.dart';

/// Inline tag editor widget for adding/removing tags on pages
class TagEditorWidget extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagEditorWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagEditorWidget> createState() => _TagEditorWidgetState();
}

class _TagEditorWidgetState extends State<TagEditorWidget> {
  late List<String> _tags;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  void didUpdateWidget(TagEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) {
      _tags = List.from(widget.tags);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;

    setState(() {
      _tags.add(trimmed);
      _controller.clear();
    });
    widget.onTagsChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    widget.onTagsChanged(_tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tag chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ..._tags.map(
              (tag) => Chip(
                label: Text(
                  '#$tag',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 14,
                  color: colorScheme.primary,
                ),
                onDeleted: () => _removeTag(tag),
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            // Add tag button
            if (!_isEditing)
              ActionChip(
                label: const Text('+ Etiket', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() => _isEditing = true);
                  _focusNode.requestFocus();
                },
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        // Input field
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Etiket adı...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            _addTag(_controller.text);
                          }
                          setState(() => _isEditing = false);
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (value) {
                      _addTag(value);
                      _focusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _isEditing = false);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tag suggestion chips (for commonly used tags)
class TagSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final List<String> selectedTags;
  final ValueChanged<String> onTagTapped;

  const TagSuggestions({
    super.key,
    required this.suggestions,
    required this.selectedTags,
    required this.onTagTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filtered = suggestions
        .where((s) => !selectedTags.contains(s))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: filtered
          .map(
            (tag) => ActionChip(
              label: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () => onTagTapped(tag),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          )
          .toList(),
    );
  }
}
