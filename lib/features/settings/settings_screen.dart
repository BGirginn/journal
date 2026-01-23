import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:journal_app/providers/database_providers.dart';

import 'package:journal_app/core/auth/auth_service.dart';

import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/features/auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          _buildProfileSection(context, ref),
          const Divider(),
          _buildAppearanceSection(ref),
          const Divider(),
          _buildBackupSection(context, ref),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Hakkında'),
            subtitle: Text('Journal App v1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isGuest = ref.watch(guestModeProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple,
        radius: 24,
        backgroundImage: user?.photoURL != null
            ? NetworkImage(user!.photoURL!)
            : null,
        child: user?.photoURL == null
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        isGuest ? 'Misafir Kullanıcı' : (user?.displayName ?? 'Kullanıcı'),
      ),
      subtitle: Text(isGuest ? 'Senkronizasyon kapalı' : (user?.email ?? '')),
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await ref.read(authServiceProvider).signOut();
          ref.read(guestModeProvider.notifier).state = false;
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildAppearanceSection(WidgetRef ref) {
    final settings = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Görünüm',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        // Theme Mode
        RadioListTile<ThemeMode>(
          title: const Text('Sistem Teması'),
          value: ThemeMode.system,
          groupValue: settings.mode,
          onChanged: (v) => notifier.setThemeMode(v!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Açık Tema'),
          value: ThemeMode.light,
          groupValue: settings.mode,
          onChanged: (v) => notifier.setThemeMode(v!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Koyu Tema'),
          value: ThemeMode.dark,
          groupValue: settings.mode,
          onChanged: (v) => notifier.setThemeMode(v!),
        ),
      ],
    );
  }

  Widget _buildBackupSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Yedekle (Backup)'),
          subtitle: const Text('Veritabanını dışa aktar'),
          onTap: () async {
            // Simple backup logic: Copy db file to Documents
            try {
              final dbFolder = await getApplicationDocumentsDirectory();
              final file = File(
                p.join(dbFolder.path, 'journal_database.sqlite'),
              );
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
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veritabanı dosyası bulunamadı.'),
                    ),
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
          onTap: () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.any,
              );

              if (result != null && result.files.single.path != null) {
                final backupFile = File(result.files.single.path!);

                if (context.mounted) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Geri Yükle?'),
                      content: const Text(
                        'Mevcut tüm verileriniz silinecek ve seçilen yedek yüklenecek. Emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Evet, Yükle'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // 1. Close DB
                    await ref.read(databaseProvider).close();

                    // 2. Overwrite file
                    final dbFolder = await getApplicationDocumentsDirectory();
                    final dbFile = File(
                      p.join(dbFolder.path, 'journal_database.sqlite'),
                    );

                    await backupFile.copy(dbFile.path);

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('Başarılı'),
                          content: const Text(
                            'Yedek başarıyla yüklendi. Uygulamanın yeni verileri görmesi için yeniden başlatılması gerekiyor.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                exit(0);
                              },
                              child: const Text('Uygulamayı Kapat'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Geri yükleme hatası: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
