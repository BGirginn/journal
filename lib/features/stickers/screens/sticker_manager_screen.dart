import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/models/user_sticker.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';
import 'package:journal_app/features/stickers/sticker_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StickerManagerScreen extends ConsumerWidget {
  const StickerManagerScreen({super.key});

  void _onRootNavTap(BuildContext context, int index) {
    context.go('/?tab=$index');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: const StickerManagerView(),
      floatingActionButtonLocation: const _FabAboveBottomBarLocation(gap: 16),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Çıkartma Oluştur',
        onPressed: () => context.push('/stickers/create'),
        child: const Icon(LucideIcons.plus),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 1,
        onItemSelected: (index) => _onRootNavTap(context, index),
      ),
    );
  }
}

class StickerManagerView extends ConsumerWidget {
  final bool isEmbeddedInLibrary;

  const StickerManagerView({super.key, this.isEmbeddedInLibrary = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerService = ref.watch(stickerServiceProvider);
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return StreamBuilder<List<UserSticker>>(
      stream: stickerService.watchMyStickers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stickers = snapshot.data ?? const <UserSticker>[];
        final recentEmoji =
            stickers.where((s) => s.type == StickerType.emoji).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final recent = <String>[];
        for (final sticker in recentEmoji) {
          if (sticker.content.trim().isEmpty) continue;
          if (!recent.contains(sticker.content)) {
            recent.add(sticker.content);
          }
          if (recent.length == 8) {
            break;
          }
        }
        final categoryCounts = <String, int>{};
        for (final sticker in stickers) {
          final category = sticker.category.trim().isEmpty
              ? 'custom'
              : sticker.category.trim();
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
        final categories = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final showStandaloneHeader = !isEmbeddedInLibrary;
        final content = stickers.isEmpty
            ? _StickersEmptyState(
                onCreate: () => context.push('/stickers/create'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecentSection(recent: recent),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Kategoriler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryTile(
                        title: category.key,
                        icon: _categoryIcon(category.key),
                        count: category.value,
                        colors: _categoryGradient(
                          category.key,
                          Theme.of(context).colorScheme,
                        ),
                      ),
                    ),
                ],
              );

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (showStandaloneHeader)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
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
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: LucideIcons.arrowLeft,
                            onTap: () => context.go('/?tab=2'),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Çıkartmalar',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Inbox',
                            onPressed: () => context.push('/notifications'),
                            icon: const Icon(LucideIcons.inbox),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Günlüklerini özelleştir',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                showStandaloneHeader ? 0 : 16,
                20,
                140,
              ),
              child: (showStandaloneHeader
                  ? Transform.translate(
                      offset: const Offset(0, -18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: content,
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EmbeddedCreateAction(
                            onCreate: () => context.push('/stickers/create'),
                          ),
                          const SizedBox(height: 12),
                          content,
                        ],
                      ),
                    )),
            ),
          ],
        );
      },
    );
  }
}

class _EmbeddedCreateAction extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmbeddedCreateAction({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Çıkartmalar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Oluştur'),
        ),
      ],
    );
  }
}

class _RecentSection extends StatelessWidget {
  final List<String> recent;

  const _RecentSection({required this.recent});

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
            'Son Kullanılanlar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              'Henüz emoji çıkartman yok',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, i) {
                return Material(
                  color: semantic.elevated,
                  borderRadius: BorderRadius.circular(radius.medium),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius.medium),
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius.medium),
                        border: Border.all(
                          color: semantic.divider.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          recent[i],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final List<Color> colors;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.count,
    required this.colors,
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
      color: semantic.card,
      borderRadius: BorderRadius.circular(radius.medium),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(radius.medium),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.medium),
            border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius.small),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  border: Border.all(
                    color: semantic.divider.withValues(alpha: 0.8),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _normalizeCategoryLabel(title),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count çıkartma',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.sparkles,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickersEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _StickersEmptyState({required this.onCreate});

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: semantic.card,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.sticker, size: 54, color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Henüz çıkartma yok',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'İlk çıkartmanı oluşturup günlüklerinde kullan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Çıkartma Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

String _normalizeCategoryLabel(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return 'Özel';
  final lower = normalized.toLowerCase();
  if (lower == 'favorites') return 'Favoriler';
  if (lower == 'custom') return 'Özel';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

IconData _categoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('duygu') || lower.contains('emoji')) {
    return LucideIcons.smile;
  }
  if (lower.contains('favori')) {
    return LucideIcons.heart;
  }
  if (lower.contains('gokyuzu')) {
    return LucideIcons.sun;
  }
  if (lower.contains('custom') || lower.contains('ozel')) {
    return LucideIcons.star;
  }
  return LucideIcons.sparkles;
}

List<Color> _categoryGradient(String category, ColorScheme colorScheme) {
  final hash = category.codeUnits.fold<int>(0, (prev, unit) => prev + unit);
  final mod = hash % 4;
  return switch (mod) {
    0 => [
      colorScheme.primary.withValues(alpha: 0.22),
      colorScheme.secondary.withValues(alpha: 0.2),
    ],
    1 => [
      colorScheme.tertiary.withValues(alpha: 0.22),
      colorScheme.primary.withValues(alpha: 0.18),
    ],
    2 => [
      colorScheme.secondary.withValues(alpha: 0.25),
      colorScheme.tertiary.withValues(alpha: 0.2),
    ],
    _ => [
      colorScheme.primaryContainer.withValues(alpha: 0.9),
      colorScheme.secondaryContainer.withValues(alpha: 0.7),
    ],
  };
}

class _FabAboveBottomBarLocation extends FloatingActionButtonLocation {
  final double gap;

  const _FabAboveBottomBarLocation({required this.gap});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final bottomInset = scaffoldGeometry.minInsets.bottom;
    final barTop =
        scaffoldGeometry.scaffoldSize.height -
        bottomInset -
        CustomBottomNavigation.kBarBottomInset -
        CustomBottomNavigation.kBarHeight;
    final y = barTop - fabSize.height - gap;
    const horizontalMargin = 16.0;
    final x = switch (scaffoldGeometry.textDirection) {
      TextDirection.rtl => scaffoldGeometry.minInsets.left + horizontalMargin,
      TextDirection.ltr =>
        scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.minInsets.right -
            horizontalMargin -
            fabSize.width,
    };
    return Offset(x, y);
  }
}
