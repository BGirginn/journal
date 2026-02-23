import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/theme/tokens/brand_spacing.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends ConsumerWidget {
  final bool isEmbeddedInLibrary;

  const HomeScreen({super.key, this.isEmbeddedInLibrary = false});

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Günaydın';
    if (hour >= 12 && hour < 17) return 'İyi Günler';
    if (hour >= 17 && hour < 22) return 'İyi Akşamlar';
    return 'İyi Geceler';
  }

  String _displayName(UserProfile? profile) {
    final firstName = profile?.firstName;
    if (firstName != null && firstName.isNotEmpty) {
      return firstName.trim();
    }
    final displayName = profile?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.trim();
    }
    return 'Kullanıcı';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final spacing =
        Theme.of(context).extension<JournalSpacingScale>() ??
        JournalSpacingScale.standard;
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    final profile = ref.watch(myProfileProvider).value;
    final journals = ref.watch(journalsProvider).value ?? const <Journal>[];
    final pageCount = ref.watch(totalPageCountProvider).value ?? 0;
    final now = DateTime.now();
    final dateString = DateFormat('EEEE d MMMM', 'tr_TR').format(now);
    final greeting = _greeting(now);
    final name = _displayName(profile);
    final headerTopPadding = isEmbeddedInLibrary ? 20.0 : 56.0;
    final contentTopPadding = isEmbeddedInLibrary ? 12.0 : 10.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, headerTopPadding, 20, 28),
          decoration: BoxDecoration(
            color: semantic.elevated,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(radius.modal),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEmbeddedInLibrary) ...[
                  Row(
                    children: [
                      Text(
                        'Anasayfa',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.9,
                              ),
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(LucideIcons.inbox),
                        tooltip: 'Inbox',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Text(dateString, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  '$greeting, $name 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, contentTopPadding, 20, 140),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Hızlı Erişim',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        title: 'Takımlar',
                        icon: LucideIcons.users,
                        tint: colorScheme.secondary,
                        gradientA: colorScheme.secondary.withValues(
                          alpha: 0.25,
                        ),
                        gradientB: colorScheme.primary.withValues(alpha: 0.2),
                        onTap: () => context.push('/teams'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        title: 'Çıkartmalar',
                        icon: LucideIcons.sticker,
                        tint: colorScheme.tertiary,
                        gradientA: colorScheme.tertiary.withValues(alpha: 0.24),
                        gradientB: colorScheme.primary.withValues(alpha: 0.18),
                        onTap: () => context.go('/?tab=1'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.sm),
                if (journals.isEmpty)
                  const _EmptyStateCard()
                else
                  _RecentJournalsCard(journals: journals.take(3).toList()),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: semantic.card,
                    borderRadius: BorderRadius.circular(radius.large),
                    border: Border.all(
                      color: semantic.divider.withValues(alpha: 0.85),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İstatistikler',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: LucideIcons.bookMarked,
                              value: journals.length,
                              label: 'Günlük',
                              tint: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: LucideIcons.fileText,
                              value: pageCount,
                              label: 'Sayfa',
                              tint: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: LucideIcons.users,
                              value: profile?.friends.length ?? 0,
                              label: 'Arkadaş',
                              tint: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color tint;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantic.elevated,
        borderRadius: BorderRadius.circular(radius.medium),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(radius.small),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: semantic.card,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radius.medium),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              LucideIcons.bookmark,
              size: 34,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Henüz günlük yok',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Henüz görüntülenecek günlük bulunmuyor.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecentJournalsCard extends StatelessWidget {
  final List<Journal> journals;

  const _RecentJournalsCard({required this.journals});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: semantic.card,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Günlükler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...journals.map(
            (journal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.bookMarked,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      journal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Color gradientA;
  final Color gradientB;
  final VoidCallback onTap;

  const _QuickTile({
    required this.title,
    required this.icon,
    required this.tint,
    required this.gradientA,
    required this.gradientB,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.medium),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semantic.card,
            borderRadius: BorderRadius.circular(radius.medium),
            border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius.small),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientA, gradientB],
                  ),
                  border: Border.all(
                    color: semantic.divider.withValues(alpha: 0.8),
                  ),
                ),
                child: Center(child: Icon(icon, color: tint, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
