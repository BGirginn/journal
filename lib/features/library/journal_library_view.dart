import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/providers/providers.dart';
import 'package:journal_app/features/library/widgets/journal_preview_card.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';
import 'package:journal_app/features/library/cover_customization_dialog.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';

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
          // Use NotebookTheme
          final theme = NostalgicThemes.getById(journal.coverStyle);

          return JournalPreviewCard(
            journal: journal,
            theme: theme,
            onTap: () => _openJournal(context, journal),
            onLongPress: () => _showJournalOptions(context, ref, journal),
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

  void _showJournalOptions(
    BuildContext context,
    WidgetRef ref,
    Journal journal,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              journal.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Cover customization
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Kapağı Özelleştir'),
              subtitle: const Text('Tema veya fotoğraf seçin'),
              onTap: () {
                Navigator.pop(ctx);
                _showCoverCustomization(context, ref, journal);
              },
            ),
            // Rename
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Yeniden Adlandır'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, journal);
              },
            ),
            // Delete
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Sil',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    final controller = TextEditingController(text: journal.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Günlük adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != journal.title) {
                Navigator.pop(context);
                final updateJournal = ref.read(updateJournalProvider);
                await updateJournal(
                  journal.copyWith(title: newTitle, updatedAt: DateTime.now()),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
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
