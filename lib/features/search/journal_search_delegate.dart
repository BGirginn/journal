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
    if (query.length < 3) {
      return const Center(child: Text('En az 3 karakter giriniz'));
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
          return const Center(child: Text('Sonuç bulunamadı'));
        }

        return ListView.builder(
          itemCount: blocks.length,
          itemBuilder: (context, index) {
            final block = blocks[index];
            final payload = TextBlockPayload.fromJson(block.payload);

            return ListTile(
              title: Text(
                payload.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Page ID: ${block.pageId}',
              ), // Ideally look up page number
              onTap: () async {
                // Navigate to editor
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
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Icon(Icons.search, size: 64, color: Colors.grey),
    );
  }
}
