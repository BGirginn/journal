import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/journal_theme.dart';

/// Theme picker dialog for selecting journal theme
class ThemePickerDialog extends StatelessWidget {
  final String? selectedThemeId;
  final void Function(JournalTheme) onSelect;

  const ThemePickerDialog({
    super.key,
    this.selectedThemeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themes = BuiltInThemes.all;

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
  final JournalTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.deepPurple, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
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
                    colors: theme.coverGradient,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    theme.coverIcon,
                    size: 28,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
            ),
            // Theme name
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.pageBackground,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.id == 'dark' ? Colors.white : Colors.black87,
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
Future<JournalTheme?> showThemePicker(
  BuildContext context, {
  String? selectedThemeId,
}) async {
  JournalTheme? result;

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
