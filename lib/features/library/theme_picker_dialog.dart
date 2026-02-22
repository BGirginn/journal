import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';

/// Theme picker dialog for selecting journal theme
class ThemePickerDialog extends StatelessWidget {
  final String? selectedThemeId;
  final void Function(NotebookTheme) onSelect;

  const ThemePickerDialog({
    super.key,
    this.selectedThemeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themes = NostalgicThemes.all;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema Seçin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isSelected = theme.id == selectedThemeId;

                  return _ThemeCard(
                    theme: theme,
                    isSelected: isSelected,
                    onTap: () {
                      onSelect(theme);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme card widget
class _ThemeCard extends StatelessWidget {
  final NotebookTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover preview
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.visuals.coverGradient,
                  ),
                  image: theme.visuals.assetPath != null
                      ? DecorationImage(
                          image: AssetImage(theme.visuals.assetPath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: theme.visuals.assetPath == null
                    ? Center(
                        child: Text(
                          theme.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            // Theme name
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.visuals.pageColor == Colors.transparent
                      ? colorScheme.surfaceContainer
                      : theme.visuals.pageColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2F241C),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show theme picker dialog
Future<NotebookTheme?> showThemePicker(
  BuildContext context, {
  String? selectedThemeId,
}) async {
  NotebookTheme? result;

  await showDialog(
    context: context,
    builder: (context) => ThemePickerDialog(
      selectedThemeId: selectedThemeId,
      onSelect: (theme) {
        result = theme;
      },
    ),
  );

  return result;
}
