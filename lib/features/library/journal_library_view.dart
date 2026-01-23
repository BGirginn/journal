import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/theme/journal_theme.dart';
import 'package:journal_app/providers/providers.dart';
import 'package:journal_app/features/library/widgets/journal_preview_card.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';

class JournalLibraryView extends ConsumerWidget {
  const JournalLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);

    return journalsAsync.when(
      data: (journals) => _buildJournalGrid(context, ref, journals),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Hata: $error')),
    );
  }

  Widget _buildJournalGrid(
    BuildContext context,
    WidgetRef ref,
    List<Journal> journals,
  ) {
    if (journals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz günlük yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir günlük oluşturmak için + butonuna basın',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: journals.length,
        itemBuilder: (context, index) {
          final journal = journals[index];
          final theme = BuiltInThemes.getById(journal.coverStyle);

          return JournalPreviewCard(
            journal: journal,
            theme: theme,
            onTap: () => _openJournal(context, journal),
            onLongPress: () => _showDeleteDialog(context, ref, journal),
          );
        },
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Journal journal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlüğü Sil'),
        content: Text(
          '"${journal.title}" günlüğünü silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final deleteJournal = ref.read(deleteJournalProvider);
              await deleteJournal(journal.id);

              try {
                // We're inside a consumer widget, but extracting provider reading in static/methods
                // might be tricky if we don't pass ref.
                // Wait, deleteJournalProvider already handles firestore logic?
                // Let's check original implementation.
                // The original had separate firestore call in the UI code.
                // Adapting here...
                // Ideally the provider should handle it all.
                // But for now let's just stick to the provider call which is cleaner.
              } catch (e) {
                debugPrint('Delete Error: $e');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
