import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Dark background color for the bar itself
    final barBackgroundColor = const Color(0xFF1E1E2C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: barBackgroundColor,
          borderRadius: BorderRadius.circular(35), // Fully rounded ends
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, 'Anasayfa'),
            _buildNavItem(context, 3, Icons.book_rounded, 'Günlükler'),
            _buildNavItem(context, 2, Icons.people_rounded, 'Arkadaşlar'),
            _buildNavItem(context, 1, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  // Helper to build explicit visual order
  // But let's look at the mapping in LibraryScreen again.
  // _titles = ['Anasayfa', 'Ayarlar', 'Arkadaşlar', 'Günlüklerim'];
  // Index mappings: 0, 1, 2, 3.
  // I will just render them in index order 0, 2, 3, 1? No, 0,1,2,3 is safest unless I refactor LibraryScreen.
  // Let's stick to 0, 2, 3, 1 as it looks better: Home, Friends, Journals, Settings.

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD04ED6), // Pink-ish
                    Color(0xFF834D9B), // Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD04ED6).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            if (!isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ] else ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
