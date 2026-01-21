import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Yedekle (Backup)'),
            subtitle: const Text('Veritabanını dışa aktar'),
            onTap: () async {
              // Simple backup logic: Copy db file to Documents
              try {
                final dbFolder = await getApplicationDocumentsDirectory();
                final file = File(p.join(dbFolder.path, 'db.sqlite'));
                if (await file.exists()) {
                  final backupPath = p.join(
                    dbFolder.path,
                    'journal_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
                  );
                  await file.copy(backupPath);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Yedeklendi: $backupPath')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Geri Yükle'),
            subtitle: const Text('Yedekten geri dön'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Henüz aktif değil')),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Hakkında'),
            subtitle: Text('Journal App v1.0.0'),
          ),
        ],
      ),
    );
  }
}
