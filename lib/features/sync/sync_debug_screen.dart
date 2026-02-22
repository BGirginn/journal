import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/oplog.dart';
import 'package:journal_app/core/sync/sync_service.dart';

class SyncDebugScreen extends ConsumerWidget {
  const SyncDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingOplogCountProvider);
    final pendingEntries = ref.watch(pendingOplogEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Queue Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pendingCount.when(
              data: (count) => Text(
                'Pending Oplog Count: $count',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Count error: $error'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingEntries.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(child: Text('Pending queue bos.'));
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _EntryCard(entry: entry);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Queue error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ref.read(syncServiceProvider).syncUp();
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('syncUp tetiklendi')));
          }
        },
        icon: const Icon(Icons.sync),
        label: const Text('Sync Up'),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final OplogEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.opType.name.toUpperCase()} • ${entry.status.name}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text('opId: ${entry.opId}'),
            Text('journalId: ${entry.journalId}'),
            if (entry.pageId != null) Text('pageId: ${entry.pageId}'),
            if (entry.blockId != null) Text('blockId: ${entry.blockId}'),
            Text('hlc: ${entry.hlc}'),
          ],
        ),
      ),
    );
  }
}
