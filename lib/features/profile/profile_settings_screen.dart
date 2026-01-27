import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/features/profile/widgets/color_theme_selector.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil ve Ayarlar')),
      body: const ProfileSettingsView(),
    );
  }
}

class ProfileSettingsView extends ConsumerStatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  ConsumerState<ProfileSettingsView> createState() =>
      _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends ConsumerState<ProfileSettingsView> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(myProfileProvider);
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return userProfileAsync.when(
      data: (profile) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profil Bölümü
            _buildProfileCard(context, profile),
            const SizedBox(height: 24),

            // Ayarlar Başlığı
            Text(
              'AYARLAR',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Görünüm Bölümü
            _buildSection(
              context,
              title: 'Görünüm',
              icon: Icons.palette_outlined,
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Tema Modu'),
                  subtitle: Text(_getThemeModeLabel(themeSettings.mode)),
                  children: [
                    RadioGroup<ThemeMode>(
                      groupValue: themeSettings.mode,
                      onChanged: (value) {
                        if (value != null) themeNotifier.setThemeMode(value);
                      },
                      child: const Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: Text('Sistem Teması'),
                            value: ThemeMode.system,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Açık Tema'),
                            value: ThemeMode.light,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Koyu Tema'),
                            value: ThemeMode.dark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ColorThemeSelector(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Veri Yönetimi Bölümü
            _buildSection(
              context,
              title: 'Veri Yönetimi',
              icon: Icons.storage_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Yedekle'),
                  subtitle: const Text('Verilerinizi yedekleyin'),
                  onTap: () async {
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
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Geri Yükle'),
                  subtitle: const Text('Yedekten geri dön'),
                  onTap: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.any);

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
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                            final dbFolder =
                                await getApplicationDocumentsDirectory();
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
            ),

            const SizedBox(height: 16),

            // Hesap Bölümü
            _buildSection(
              context,
              title: 'Hesap',
              icon: Icons.account_circle_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text(
                          'Çıkış yapmak istediğinize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Çıkış',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hakkında Bölümü
            _buildSection(
              context,
              title: 'Hakkında',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: const Text('Versiyon'),
                  trailing: Text(_packageInfo?.version ?? 'Yükleniyor...'),
                ),
                ListTile(
                  title: const Text('Lisanslar'),
                  onTap: () => showLicensePage(context: context),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Hata: $err')),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile? profile) {
    if (profile == null) {
      return const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Misafir Kullanıcı'),
          subtitle: Text('Giriş yapmadınız'),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Text(
                      profile.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        profile.displayId,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1.1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: profile.displayId),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID kopyalandı')),
                          );
                        },
                        tooltip: 'ID Kopyala',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(child: Column(children: children));
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistem Teması';
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
    }
  }
}
