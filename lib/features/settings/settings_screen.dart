import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
          _buildBackupSection(context),
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

  Widget _buildBackupSection(BuildContext context) {
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Henüz aktif değil')));
          },
        ),
      ],
    );
  }
}
