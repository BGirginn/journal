import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/theme/theme_variant.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/features/notifications/notifications_repository.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, this.onInboxTap});

  final VoidCallback? onInboxTap;

  String _avatarInitial(String? name) {
    final normalized = name?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '?';
    }
    return normalized.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(myProfileProvider);
    final inviteCountAsync = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<JournalSemanticColors>();
    final isDark = theme.brightness == Brightness.dark;
    final activeVariant = ref.watch(themeProvider).effectiveVariant;
    final isVioletTheme =
        activeVariant == AppThemeVariant.violetNebulaJournal ||
        activeVariant == AppThemeVariant.testedTheme;

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    );

    return Drawer(
      shape: shape,
      backgroundColor: isVioletTheme
          ? (semantic?.elevated ?? colorScheme.surface)
          : colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isVioletTheme
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    semantic?.background ?? colorScheme.surface,
                    semantic?.elevated ?? colorScheme.surface,
                    semantic?.card ?? colorScheme.surface,
                  ],
                  stops: const [0.0, 0.62, 1.0],
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Profile Header ───
              userProfileAsync.when(
                data: (profile) => _buildHeader(
                  context,
                  profile,
                  isVioletTheme: isVioletTheme,
                ),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) =>
                    _buildHeader(context, null, isVioletTheme: isVioletTheme),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Menu Items ───
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_outlined,
                      label: 'Anasayfa',
                      isVioletTheme: isVioletTheme,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people_outline_rounded,
                      label: 'Arkadaşlar',
                      isVioletTheme: isVioletTheme,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.group_outlined,
                      label: 'Takımlarım',
                      isVioletTheme: isVioletTheme,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/teams');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Bildirimler',
                      isVioletTheme: isVioletTheme,
                      badge: inviteCountAsync.when(
                        data: (count) => count,
                        loading: () => 0,
                        error: (e, s) => 0,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (onInboxTap != null) {
                          onInboxTap!.call();
                        } else {
                          context.push('/notifications');
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Çıkartmalarım',
                      isVioletTheme: isVioletTheme,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/stickers');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Sign Out ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isVioletTheme && isDark
                      ? colorScheme.errorContainer.withValues(alpha: 0.22)
                      : null,
                  dense: true,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final router = GoRouter.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text(
                          'Çıkış yapmak istediğinize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                      try {
                        await ref.read(authServiceProvider).signOut();
                        ref.read(needsProfileSetupProvider.notifier).state =
                            null;
                        router.go('/login');
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Çıkış yapılamadı: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserProfile? profile, {
    required bool isVioletTheme,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final semantic = theme.extension<JournalSemanticColors>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: isVioletTheme
              ? (semantic?.card ?? colorScheme.surface).withValues(
                  alpha: isDark ? 0.82 : 0.88,
                )
              : colorScheme.surface.withValues(alpha: isDark ? 0.42 : 1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: isVioletTheme ? (isDark ? 0.92 : 0.84) : 0.54,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary,
              backgroundImage: profile?.photoUrl != null
                  ? NetworkImage(profile!.photoUrl!)
                  : null,
              child: profile?.photoUrl == null
                  ? Text(
                      _avatarInitial(profile?.displayName),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'Misafir',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile?.username != null)
                    Text(
                      '@${profile!.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
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
    required bool isVioletTheme,
    bool isSelected = false,
    int badge = 0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: badge > 0
              ? Badge(
                  label: Text('$badge'),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(
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
              ? colorScheme.primaryContainer.withValues(
                  alpha: isVioletTheme ? 0.42 : 0.3,
                )
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
