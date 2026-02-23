import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/theme/tokens/brand_spacing.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';
import 'package:journal_app/features/library/cover_customization_dialog.dart';
import 'package:journal_app/features/library/widgets/journal_preview_card.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:journal_app/providers/providers.dart';

class JournalLibraryView extends ConsumerWidget {
  const JournalLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);

    return journalsAsync.when(
      data: (journals) => _buildJournalContent(context, ref, journals),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildJournalContent(
    BuildContext context,
    WidgetRef ref,
    List<Journal> journals,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final spacing =
        Theme.of(context).extension<JournalSpacingScale>() ??
        JournalSpacingScale.standard;

    if (journals.isEmpty) {
      return _buildEmptyState(context, spacing, l10n);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, spacing, l10n)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.md,
            spacing.md,
            spacing.xxl,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final journal = journals[index];
              final theme = NostalgicThemes.getById(journal.coverStyle);

              return JournalPreviewCard(
                journal: journal,
                theme: theme,
                visualMode: JournalCardVisualMode.coverFirst,
                onTap: () => _openJournal(context, journal),
                onLongPress: () => _showJournalOptions(context, ref, journal),
              );
            }, childCount: journals.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    JournalSpacingScale spacing,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final now = DateTime.now();

    final greeting = now.hour < 12
        ? l10n.libraryGreetingMorning
        : now.hour < 18
        ? l10n.libraryGreetingAfternoon
        : l10n.libraryGreetingEvening;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.libraryHeaderYourJournals,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: semantic.elevated,
              borderRadius: BorderRadius.circular(radius.large),
              border: Border.all(color: semantic.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: colorScheme.primary),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    l10n.librarySectionSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    JournalSpacingScale spacing,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BrandColors.primary600, BrandColors.primary500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            SizedBox(height: spacing.lg),
            Text(
              l10n.libraryEmptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.xs),
            Text(
              l10n.libraryEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openJournal(BuildContext context, Journal journal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JournalViewScreen(journal: journal),
      ),
    );
  }

  void _showJournalOptions(
    BuildContext context,
    WidgetRef ref,
    Journal journal,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Text(journal.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.remove_red_eye_outlined),
              title: Text(l10n.libraryActionPreview),
              onTap: () {
                Navigator.pop(ctx);
                _showLivePreviewSheet(context, journal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.libraryActionCustomizeCover),
              onTap: () {
                Navigator.pop(ctx);
                _showCoverCustomization(context, ref, journal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.libraryActionRename),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, journal);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                l10n.libraryActionDelete,
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog(context, ref, journal);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLivePreviewSheet(BuildContext context, Journal journal) {
    final theme = NostalgicThemes.getById(journal.coverStyle);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.libraryPreviewTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                height: 360,
                child: JournalPreviewCard(
                  journal: journal,
                  theme: theme,
                  visualMode: JournalCardVisualMode.livePreview,
                  onTap: () {},
                  onLongPress: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCoverCustomization(
    BuildContext context,
    WidgetRef ref,
    Journal journal,
  ) async {
    final result = await showCoverCustomization(
      context,
      currentCoverStyle: journal.coverStyle,
      currentCoverImageUrl: journal.coverImageUrl,
    );

    if (result != null) {
      final updateJournal = ref.read(updateJournalProvider);
      await updateJournal(
        journal.copyWith(
          coverStyle: result['coverStyle'] ?? journal.coverStyle,
          coverImageUrl: result['coverImageUrl'],
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Journal journal) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: journal.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.libraryRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.libraryRenameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              Navigator.pop(dialogContext);
              if (newTitle.isNotEmpty && newTitle != journal.title) {
                final updateJournal = ref.read(updateJournalProvider);
                await updateJournal(
                  journal.copyWith(title: newTitle, updatedAt: DateTime.now()),
                );
              }
            },
            child: Text(l10n.editorApply),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Journal journal) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.libraryDeleteTitle),
        content: Text(l10n.libraryDeleteMessage(journal.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final deleteJournal = ref.read(deleteJournalProvider);
              await deleteJournal(journal.id);
            },
            child: Text(l10n.libraryActionDelete),
          ),
        ],
      ),
    );
  }
}
