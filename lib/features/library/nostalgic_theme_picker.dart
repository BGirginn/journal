import 'package:flutter/material.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';

/// Beautiful theme picker with live previews
class NostalgicThemePicker extends StatelessWidget {
  final String? selectedThemeId;
  final ValueChanged<NotebookTheme> onSelect;

  const NostalgicThemePicker({
    super.key,
    this.selectedThemeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: Colors.deepPurple),
              SizedBox(width: 12),
              Text(
                'Defter Teması Seç',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Her tema benzersiz bir deneyim sunar',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: NostalgicThemes.all.length,
              itemBuilder: (context, index) {
                final theme = NostalgicThemes.all[index];
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
        ],
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.deepPurple, width: 3)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withAlpha(50),
                    blurRadius: 12,
                  ),
                ]
              : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover preview
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.visuals.coverGradient,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    // Texture hint
                    if (theme.visuals.hasHoles)
                      Positioned(
                        left: 8,
                        top: 10,
                        bottom: 10,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (_) => Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(100),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Theme icon
                    Center(
                      child: Icon(
                        _getThemeIcon(),
                        color: Colors.white.withAlpha(200),
                        size: 36,
                      ),
                    ),
                    // Selected badge
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.deepPurple,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.visuals.pageColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      theme.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.visuals.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.visuals.textColor.withAlpha(150),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon() {
    switch (theme.id) {
      case 'school_90s':
        return Icons.school;
      case 'leather_journal':
        return Icons.menu_book;
      case 'sketchbook':
        return Icons.brush;
      case 'bullet':
        return Icons.checklist;
      case 'romantic':
        return Icons.favorite;
      case 'midnight':
        return Icons.nightlight_round;
      case 'kraft':
        return Icons.eco;
      case 'graph':
        return Icons.grid_on;
      default:
        return Icons.book;
    }
  }
}

/// Show theme picker as bottom sheet
Future<NotebookTheme?> showNostalgicThemePicker(
  BuildContext context, {
  String? selectedThemeId,
}) async {
  NotebookTheme? result;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => NostalgicThemePicker(
        selectedThemeId: selectedThemeId,
        onSelect: (theme) => result = theme,
      ),
    ),
  );
  return result;
}
