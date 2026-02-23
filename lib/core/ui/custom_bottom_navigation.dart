import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNavigation extends StatelessWidget {
  static const double kWidgetHeight = 136;
  static const double kBarBottomInset = 22;
  static const double kBarHeight = 60;

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _items = <_NavItem>[
    _NavItem(0, LucideIcons.bookMarked, 'Günlükler'),
    _NavItem(1, LucideIcons.sticker, 'Çıkartmalar'),
    _NavItem(2, LucideIcons.home, 'Anasayfa'),
    _NavItem(3, LucideIcons.users, 'Arkadaşlar'),
    _NavItem(4, LucideIcons.user, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = selectedIndex.clamp(0, _items.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellColor = colorScheme.surface.withValues(alpha: isDark ? 0.92 : 1);
    final iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final selectedText = colorScheme.onPrimary;

    return SizedBox(
      height: kWidgetHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: kBarBottomInset,
            child: SafeArea(
              top: false,
              child: Container(
                height: kBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: shellColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.75),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: isDark ? 0.35 : 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _items.map((item) {
                    final isSelected = item.index == selected;
                    return _NavAction(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      iconColor: iconColor,
                      selectedTextColor: selectedText,
                      onTap: () => onItemSelected(item.index),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color iconColor;
  final Color selectedTextColor;
  final VoidCallback onTap;

  const _NavAction({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.iconColor,
    required this.selectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSelected ? 18 : 20,
                color: isSelected ? selectedTextColor : iconColor,
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: isSelected ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: isSelected
                          ? Text(
                              label,
                              key: ValueKey('nav_label_$label'),
                              style: TextStyle(
                                color: selectedTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : SizedBox(
                              key: ValueKey('nav_label_hidden_$label'),
                              width: 0,
                              height: 0,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final String label;

  const _NavItem(this.index, this.icon, this.label);
}
