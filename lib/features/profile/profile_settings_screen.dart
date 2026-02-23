import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/localization/locale_provider.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/theme/theme_variant.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/database/storage_service.dart';
import 'package:journal_app/core/errors/app_error.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSettingsTitle)),
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
  String _dbSizeText = 'Hesaplanıyor...';
  bool _isUploadingAvatar = false;
  bool _isLinkingApple = false;

  String _avatarInitial(String? name) {
    final normalized = name?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '?';
    }
    return normalized.substring(0, 1).toUpperCase();
  }

  String _normalizeLocaleSelection(Locale? locale) {
    final code = locale?.languageCode.toLowerCase();
    if (code == 'tr' || code == 'en') {
      return code!;
    }
    return 'system';
  }

  bool _isTurkish(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';
  }

  String _paletteTitle(BuildContext context) {
    return _isTurkish(context) ? 'Tema Paleti' : 'Theme Palette';
  }

  String _paletteLabel(BuildContext context, AppThemeVariant variant) {
    final isTurkish = _isTurkish(context);
    return switch (variant) {
      AppThemeVariant.calmEditorialPremium =>
        isTurkish ? 'Calm Editorial Premium' : 'Calm Editorial Premium',
      AppThemeVariant.inkPurple =>
        isTurkish ? 'Mürekkep & Mor' : 'Ink & Purple',
      AppThemeVariant.deepDarkCreator =>
        isTurkish ? 'Deep Dark Creator' : 'Deep Dark Creator',
      AppThemeVariant.neoAnalogJournal =>
        isTurkish ? 'Neo Analog Journal' : 'Neo Analog Journal',
      AppThemeVariant.minimalProductivityPro =>
        isTurkish ? 'Minimal Productivity Pro' : 'Minimal Productivity Pro',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _calculateDbSize();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _calculateDbSize() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/journal_database.sqlite');
      if (await dbFile.exists()) {
        final bytes = await dbFile.length();
        final sizeText = _formatBytes(bytes);
        if (mounted) {
          setState(() => _dbSizeText = sizeText);
        }
      } else {
        if (mounted) {
          setState(() => _dbSizeText = '0 B');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dbSizeText = 'Hesaplanamadı');
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamerayı Aç'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);

      final file = File(picked.path);
      final storageService = ref.read(storageServiceProvider);
      final storagePath = await storageService.uploadFile(
        file,
        customPath: 'profile_photo.jpg',
      );

      if (storagePath != null) {
        final downloadUrl = await storageService.getDownloadUrl(storagePath);
        if (downloadUrl != null) {
          await ref.read(userServiceProvider).updateProfilePhoto(downloadUrl);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İsim Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Görünen Ad',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await ref.read(userServiceProvider).updateDisplayName(newName);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('İsim güncellendi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _handleLinkApple() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLinkingApple = true);
    try {
      await ref.read(authServiceProvider).linkAppleToCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.linkAppleSuccess)));
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        AuthError(code: 'auth/provider_already_linked_apple') =>
          l10n.linkAppleAlreadyLinked,
        AuthError(code: 'auth/apple_credential_already_in_use') =>
          l10n.linkAppleCredentialInUse,
        AuthError(code: 'auth/requires_recent_login_for_link') =>
          l10n.linkAppleNeedsRecentLogin,
        AuthError(code: 'auth/apple_sign_in_ios_only') =>
          l10n.linkAppleUnsupported,
        AuthError() => '${l10n.errorPrefix}: ${e.message}',
        _ => '${l10n.errorPrefix}: $e',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLinkingApple = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(authStateProvider);
    final userProfileAsync = ref.watch(myProfileProvider);
    final linkedProviderIds = ref
        .read(authServiceProvider)
        .getCurrentProviderIds();
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final locale = ref.watch(localeProvider);
    final localeSelection = _normalizeLocaleSelection(locale);
    final localeNotifier = ref.read(localeProvider.notifier);

    return userProfileAsync.when(
      data: (profile) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // Profil Bölümü
            _buildProfileCard(context, profile),
            const SizedBox(height: 24),

            // Ayarlar Başlığı
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Görünüm Bölümü
            _buildSection(
              context,
              title: l10n.appearanceTitle,
              icon: Icons.palette_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.brightness_6_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.themeModeTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: const Icon(Icons.light_mode),
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: const Icon(Icons.dark_mode),
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {themeSettings.mode},
                          onSelectionChanged: (Set<ThemeMode> selection) {
                            themeNotifier.setThemeMode(selection.first);
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            selectedForegroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Icon(
                            Icons.color_lens_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _paletteTitle(context),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AppThemeVariant>(
                        initialValue: themeSettings.effectiveVariant,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AppThemeVariant.values
                            .map(
                              (variant) => DropdownMenuItem<AppThemeVariant>(
                                value: variant,
                                child: Text(_paletteLabel(context, variant)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          themeNotifier.setThemeVariant(value);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Language Selector
                      Row(
                        children: [
                          Icon(
                            Icons.language_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.language,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: localeSelection,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(l10n.languageSystem),
                          ),
                          DropdownMenuItem(
                            value: 'tr',
                            child: Text(l10n.languageTurkish),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n.languageEnglish),
                          ),
                        ],
                        onChanged: (value) async {
                          try {
                            if (value == null || value == 'system') {
                              await localeNotifier.setLocale(null);
                              final systemLanguage = PlatformDispatcher
                                  .instance
                                  .locale
                                  .languageCode;
                              await ref
                                  .read(userServiceProvider)
                                  .updatePreferredLanguage(systemLanguage);
                            } else {
                              await localeNotifier.setLocale(Locale(value));
                              await ref
                                  .read(userServiceProvider)
                                  .updatePreferredLanguage(value);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${l10n.errorPrefix}: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yedekleme özelliği çok yakında!'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Önbelleği Temizle'),
                  subtitle: const Text('Geçici dosyaları siler'),
                  onTap: () {
                    PaintingBinding.instance.imageCache.clear();
                    PaintingBinding.instance.imageCache.clearLiveImages();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Önbellek temizlendi')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.data_usage_outlined),
                  title: const Text('Veritabanı Boyutu'),
                  trailing: Text(
                    _dbSizeText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _calculateDbSize,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hesap Bölümü
            _buildSection(
              context,
              title: l10n.accountTitle,
              icon: Icons.account_circle_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LinkedAccountsSection(
                    providerIds: linkedProviderIds,
                    showAppleLinkButton:
                        !kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS &&
                        !linkedProviderIds.contains('apple.com'),
                    isLinkingApple: _isLinkingApple,
                    onLinkApple: _isLinkingApple ? null : _handleLinkApple,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.signOut,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.signOutConfirmTitle),
                        content: Text(l10n.signOutConfirmMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.signOut,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await ref.read(authServiceProvider).signOut();
                        ref.read(needsProfileSetupProvider.notifier).state =
                            null;
                        if (context.mounted) {
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.errorPrefix}: $e')),
                          );
                        }
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
              title: l10n.aboutTitle,
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: Text(l10n.version),
                  trailing: Text(_packageInfo?.version ?? l10n.loading),
                ),
                ListTile(
                  title: Text(l10n.licenses),
                  onTap: () => showLicensePage(context: context),
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('${l10n.errorPrefix}: $err')),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile? profile) {
    final l10n = AppLocalizations.of(context)!;
    if (profile == null) {
      return const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Misafir Kullanıcı'),
          subtitle: Text('Giriş yapmadınız'),
        ),
      );
    }

    final displayName = profile.displayName.trim().isEmpty
        ? 'Kullanıcı'
        : profile.displayName.trim();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar with change option
            GestureDetector(
              onTap: _isUploadingAvatar ? null : _changeAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Text(
                            _avatarInitial(displayName),
                            style: TextStyle(
                              fontSize: 32,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : null,
                  ),
                  // Upload indicator or camera icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          width: 2,
                        ),
                      ),
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Editable display name
                  GestureDetector(
                    onTap: () => _editDisplayName(displayName),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  if (profile.username != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: profile.username!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.copyUsernameSuccess)),
                            );
                          },
                          tooltip: l10n.copyUsernameTooltip,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
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
}

class LinkedAccountsSection extends StatelessWidget {
  const LinkedAccountsSection({
    super.key,
    required this.providerIds,
    required this.showAppleLinkButton,
    required this.isLinkingApple,
    required this.onLinkApple,
  });

  final Set<String> providerIds;
  final bool showAppleLinkButton;
  final bool isLinkingApple;
  final VoidCallback? onLinkApple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasGoogle = providerIds.contains('google.com');
    final hasApple = providerIds.contains('apple.com');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.linkedAccountsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _ProviderRow(
          icon: Icons.g_mobiledata,
          providerLabel: l10n.linkedProviderGoogle,
          connected: hasGoogle,
        ),
        const SizedBox(height: 8),
        _ProviderRow(
          icon: Icons.apple,
          providerLabel: l10n.linkedProviderApple,
          connected: hasApple,
        ),
        if (showAppleLinkButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLinkApple,
              icon: isLinkingApple
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(l10n.linkAppleAction),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.icon,
    required this.providerLabel,
    required this.connected,
  });

  final IconData icon;
  final String providerLabel;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final statusText = connected
        ? l10n.linkedStatusConnected
        : l10n.linkedStatusNotConnected;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            providerLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: connected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: connected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
