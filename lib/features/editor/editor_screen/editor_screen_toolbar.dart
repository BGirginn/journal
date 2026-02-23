part of '../editor_screen.dart';

extension _EditorToolbarExtension on _EditorScreenState {
  Widget _buildToolbar(bool topBarSolid) {
    final l10n = AppLocalizations.of(context)!;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final spacing =
        Theme.of(context).extension<JournalSpacingScale>() ??
        JournalSpacingScale.standard;
    final elevation =
        Theme.of(context).extension<JournalElevationScale>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalElevationScale.dark
            : JournalElevationScale.light);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.md, 0, spacing.md, spacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius.modal),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.xs,
                vertical: spacing.xs,
              ),
              decoration: BoxDecoration(
                color: semantic.floatingToolbar.withValues(
                  alpha: topBarSolid ? 0.95 : 0.88,
                ),
                borderRadius: BorderRadius.circular(radius.modal),
                border: Border.all(color: semantic.divider),
                boxShadow: elevation.toolShadow,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolBtn(
                      icon: Icons.pan_tool_alt_rounded,
                      tooltip: l10n.editorToolSelect,
                      isSelected: _mode == EditorMode.select,
                      onTap: () => _applyState(() {
                        _mode = EditorMode.select;
                        _eraserPreviewPoint = null;
                      }),
                    ),
                    _ToolBtn(
                      icon: Icons.text_fields_rounded,
                      tooltip: l10n.editorToolText,
                      isSelected: _mode == EditorMode.text,
                      onTap: () {
                        _addTextBlock();
                        _applyState(() => _mode = EditorMode.text);
                      },
                    ),
                    _ToolBtn(
                      icon: Icons.image_outlined,
                      tooltip: l10n.editorMediaImage,
                      isSelected: false,
                      onTap: _addImage,
                    ),
                    _ToolBtn(
                      icon: Icons.videocam_outlined,
                      tooltip: l10n.editorMediaVideo,
                      isSelected: false,
                      onTap: _addVideoBlock,
                    ),
                    _ToolBtn(
                      icon: Icons.mic_none_rounded,
                      tooltip: l10n.editorMediaAudio,
                      isSelected: false,
                      onTap: _recordAudio,
                    ),
                    _ToolBtn(
                      icon: Icons.emoji_emotions_outlined,
                      tooltip: l10n.editorToolSticker,
                      isSelected: false,
                      onTap: _handleStickerPicker,
                    ),
                    _ToolBtn(
                      icon: Icons.draw_rounded,
                      tooltip: l10n.editorToolDraw,
                      isSelected:
                          _mode == EditorMode.draw || _mode == EditorMode.erase,
                      onTap: () => _applyState(() {
                        _mode = EditorMode.draw;
                        _eraserPreviewPoint = null;
                        if (_penColor == Colors.black &&
                            (_theme.visuals.assetPath != null ||
                                _theme.visuals.pageColor.computeLuminance() <
                                    0.3)) {
                          _penColor = Colors.white;
                        }
                      }),
                    ),
                    _ToolBtn(
                      icon: Icons.cleaning_services_outlined,
                      tooltip: l10n.editorToolErase,
                      isSelected: _mode == EditorMode.erase,
                      onTap: () => _applyState(() => _mode = EditorMode.erase),
                    ),
                    _ToolBtn(
                      icon: Icons.label_outline_rounded,
                      tooltip: l10n.editorToolTag,
                      isSelected: false,
                      onTap: _showTagEditor,
                    ),
                    if (_mode == EditorMode.select)
                      _ToolBtn(
                        icon: Icons.filter_1_rounded,
                        tooltip: l10n.editorToolZoomReset,
                        isSelected: false,
                        onTap: _resetPageZoom,
                      ),
                    if (_selectedBlockId != null) ...[
                      Container(
                        width: 1,
                        height: 28,
                        margin: EdgeInsets.symmetric(horizontal: spacing.xs),
                        color: semantic.divider,
                      ),
                      if (_getSelectedBlockType() == BlockType.image) ...[
                        _ToolBtn(
                          icon: Icons.rotate_right_rounded,
                          tooltip: l10n.editorToolRotate,
                          isSelected: false,
                          onTap: _showRotateDialog,
                        ),
                        _ToolBtn(
                          icon: Icons.style_outlined,
                          tooltip: l10n.editorToolFrame,
                          isSelected: false,
                          onTap: _showFramePicker,
                        ),
                      ],
                      _ToolBtn(
                        icon: Icons.delete_outline_rounded,
                        tooltip: l10n.editorToolDelete,
                        isSelected: false,
                        isDanger: true,
                        onTap: _deleteSelectedBlock,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final spacing =
        Theme.of(context).extension<JournalSpacingScale>() ??
        JournalSpacingScale.standard;
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
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.xs,
        spacing.md,
        spacing.sm,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Row(
        children: [
          if (_mode == EditorMode.draw) ...[
            // Colors
            ...[
              colorScheme.onSurface,
              Colors.white,
              BrandColors.primary600,
              semantic.mutedRose,
              semantic.softMint,
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
