import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    );

    return Drawer(
      shape: shape,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 16, 24),
              child: Text(
                'Journal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),

            _buildDrawerItem(
              context,
              icon: Icons.home_outlined,
              label: 'Anasayfa',
              onTap: () {
                context.pop(); // Close drawer
                context.go('/');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.group_outlined,
              label: 'Takımlarım',
              onTap: () {
                context.pop();
                context.push('/teams');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.sticky_note_2_outlined,
              label: 'Çıkartmalarım',
              onTap: () {
                context.pop();
                context.push('/stickers');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person_outlined,
              label: 'Profil ve Ayarlar',
              onTap: () {
                context.pop();
                context.push('/profile');
              },
            ),
            // Other items can stay or be removed if redundant with BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          onTap: onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }
}
