part of '../editor_screen.dart';

extension _EditorToolbarExtension on _EditorScreenState {
  Widget _buildToolbar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolBtn(
            Icons.pan_tool_alt,
            l10n.editorToolSelect,
            _mode == EditorMode.select,
            () => _applyState(() {
              _mode = EditorMode.select;
              _eraserPreviewPoint = null;
            }),
          ),
          _ToolBtn(
            Icons.text_fields,
            l10n.editorToolText,
            _mode == EditorMode.text,
            () => _addTextBlock(),
          ),
          _ToolBtn(
            Icons.edit,
            l10n.editorToolDraw,
            _mode == EditorMode.draw,
            () => _applyState(() {
              _mode = EditorMode.draw;
              _eraserPreviewPoint = null;
              if (_penColor == Colors.black) {
                final pageLooksDark =
                    _theme.visuals.assetPath != null ||
                    _theme.visuals.pageColor.computeLuminance() < 0.3;
                if (pageLooksDark) {
                  _penColor = Colors.white;
                }
              }
            }),
          ),
          _ToolBtn(
            Icons.cleaning_services_outlined,
            l10n.editorToolErase,
            _mode == EditorMode.erase,
            () => _applyState(() => _mode = EditorMode.erase),
          ),
          _ToolBtn(
            Icons.add_circle,
            l10n.editorToolMedia,
            false,
            _showMediaPicker,
          ),
          _ToolBtn(
            Icons.emoji_emotions_outlined,
            l10n.editorToolSticker,
            false,
            _handleStickerPicker,
          ),
          _ToolBtn(
            Icons.label_outline,
            l10n.editorToolTag,
            false,
            _showTagEditor,
          ),
          if (_mode == EditorMode.select)
            _ToolBtn(
              Icons.filter_1,
              l10n.editorToolZoomReset,
              false,
              _resetPageZoom,
            ),
          if (_selectedBlockId != null) ...[
            if (_getSelectedBlockType() == BlockType.image) ...[
              _ToolBtn(
                Icons.rotate_right,
                l10n.editorToolRotate,
                false,
                _showRotateDialog,
              ),
              _ToolBtn(
                Icons.style,
                l10n.editorToolFrame,
                false,
                _showFramePicker,
              ),
            ],
            _ToolBtn(
              Icons.delete,
              l10n.editorToolDelete,
              false,
              _deleteSelectedBlock,
            ),
          ],
        ],
      ),
    );
  }

  BlockType? _getSelectedBlockType() {
    if (_selectedBlockId == null) return null;
    try {
      return _blocks.firstWhere((b) => b.id == _selectedBlockId).type;
    } catch (_) {
      return null;
    }
  }

  Widget _buildPenOptions() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final pageLooksDark =
        _theme.visuals.assetPath != null ||
        _theme.visuals.pageColor.computeLuminance() < 0.35;
    final useDarkPanel = isDarkTheme || pageLooksDark;
    final panelColor = useDarkPanel
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerHighest;
    final textColor = useDarkPanel
        ? colorScheme.onSurface
        : colorScheme.onSurface;
    final dividerColor = useDarkPanel
        ? colorScheme.outlineVariant.withValues(alpha: 0.9)
        : colorScheme.outlineVariant.withValues(alpha: 0.8);
    final selectedBg = useDarkPanel
        ? colorScheme.primary.withValues(alpha: 0.25)
        : colorScheme.primary.withValues(alpha: 0.16);
    final selectedBorderColor = useDarkPanel
        ? colorScheme.onSurface.withValues(alpha: 0.55)
        : colorScheme.primary.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Row(
        children: [
          if (_mode == EditorMode.draw) ...[
            // Colors
            ...[
              Colors.black,
              Colors.white,
              Colors.blue,
              Colors.red,
              Colors.green,
            ].map(
              (c) => GestureDetector(
                onTap: () => _applyState(() => _penColor = c),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    // Keep white swatch visible on light surfaces.
                    border: c == Colors.white
                        ? Border.all(color: dividerColor, width: 1.2)
                        : null,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _penColor == c
                          ? Border.all(
                              color: useDarkPanel
                                  ? colorScheme.onSurface
                                  : colorScheme.primary,
                              width: 2.5,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(color: dividerColor),
          ] else ...[
            Icon(Icons.cleaning_services_outlined, color: textColor),
            const SizedBox(width: 8),
            Text(l10n.editorEraserSize, style: TextStyle(color: textColor)),
            const SizedBox(width: 12),
          ],
          // Widths
          ...[2.0, 4.0, 8.0].map(
            (w) => GestureDetector(
              onTap: () => _applyState(() => _penWidth = w),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _penWidth == w ? selectedBg : null,
                  border: Border.all(
                    color: _penWidth == w
                        ? selectedBorderColor
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Container(
                    width: w * 2,
                    height: w * 2,
                    decoration: BoxDecoration(
                      color: _mode == EditorMode.erase ? textColor : _penColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Clear
          IconButton(
            icon: Icon(Icons.delete_outline, color: textColor),
            onPressed: () {
              _applyState(() {
                _strokes = [];
                _isDirty = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
