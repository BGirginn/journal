import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/theme/journal_theme.dart';
import 'package:journal_app/providers/providers.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';
import 'package:journal_app/features/library/theme_picker_dialog.dart';
import 'package:journal_app/core/database/firestore_service.dart';

/// Library screen - displays list of journals
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Günlüklerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: journalsAsync.when(
        data: (journals) => _buildJournalGrid(context, ref, journals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Günlük'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
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
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz günlük yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir günlük oluşturmak için + butonuna basın',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

          return _JournalCard(
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

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String selectedThemeId = 'default';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedTheme = BuiltInThemes.getById(selectedThemeId);

          return AlertDialog(
            title: const Text('Yeni Günlük'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Günlük Adı',
                    hintText: 'Örn: Seyahat Notlarım',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tema',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final theme = await showThemePicker(
                      context,
                      selectedThemeId: selectedThemeId,
                    );
                    if (theme != null) {
                      setState(() => selectedThemeId = theme.id);
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedTheme.coverGradient,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(selectedTheme.coverIcon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          selectedTheme.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    _createJournal(
                      context,
                      ref,
                      controller.text.trim(),
                      selectedThemeId,
                    );
                  }
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createJournal(
    BuildContext context,
    WidgetRef ref,
    String title,
    String themeId,
  ) async {
    Navigator.pop(context);
    final journalDao = ref.read(journalDaoProvider);
    final pageDao = ref.read(pageDaoProvider);

    final journal = Journal(title: title, coverStyle: themeId);
    await journalDao.insertJournal(journal);

    // Create first page
    final firstPage = model.Page(journalId: journal.id, pageIndex: 0);
    await pageDao.insertPage(firstPage);

    // Sync to Firestore
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createJournal(journal);
      await firestoreService.createPage(firstPage);
    } catch (e) {
      debugPrint('Firestore Sync Error: $e');
    }
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
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.deleteJournal(journal.id);
              } catch (e) {
                debugPrint('Firestore Delete Error: $e');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

/// Journal card widget
class _JournalCard extends StatelessWidget {
  final Journal journal;
  final JournalTheme theme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _JournalCard({
    required this.journal,
    required this.theme,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.coverGradient,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    theme.coverIcon,
                    size: 48,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
            ),
            // Title
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      journal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(journal.updatedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
