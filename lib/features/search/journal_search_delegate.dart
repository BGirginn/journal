import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/features/editor/editor_screen.dart';

class JournalSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  JournalSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (query.length < 3) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'En az 3 karakter giriniz',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Perform search
    return FutureBuilder<List<Block>>(
      future: ref.read(blockDaoProvider).searchBlocks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final blocks = snapshot.data ?? [];

        if (blocks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  '"$query" için sonuç bulunamadı',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: blocks.length,
          itemBuilder: (context, index) {
            final block = blocks[index];
            final payload = TextBlockPayload.fromJson(block.payload);

            return FutureBuilder(
              future: _getBlockLocation(block),
              builder: (context, locationSnapshot) {
                final location = locationSnapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.text_snippet,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    payload.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    location ?? 'Yükleniyor...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () async {
                    final pageDao = ref.read(pageDaoProvider);
                    final journalDao = ref.read(journalDaoProvider);

                    final page = await pageDao.getPageById(block.pageId);
                    if (page != null) {
                      final journal = await journalDao.getById(page.journalId);
                      if (journal != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditorScreen(journal: journal, page: page),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String?> _getBlockLocation(Block block) async {
    try {
      final pageDao = ref.read(pageDaoProvider);
      final journalDao = ref.read(journalDaoProvider);
      final page = await pageDao.getPageById(block.pageId);
      if (page == null) return null;
      final journal = await journalDao.getById(page.journalId);
      if (journal == null) return null;
      return '${journal.title} • Sayfa ${page.pageIndex + 1}';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Günlüklerinizde arayın',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Metin bloklarında arama yapılır',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
