import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class ColorThemeSelector extends ConsumerWidget {
  const ColorThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColorTheme.values.map((theme) {
            return _ColorThemeCard(
              theme: theme,
              isSelected: theme == themeSettings.colorTheme,
              onTap: () => notifier.setColorTheme(theme),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ColorThemeCard extends StatelessWidget {
  final AppColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorThemeCard({
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
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: theme.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.color
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.color,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 20),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                theme.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.color : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
