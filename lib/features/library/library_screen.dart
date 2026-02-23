import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';

/// Library screen - displays list of journals
import 'package:journal_app/features/home/home_screen.dart';
import 'package:journal_app/features/friends/friends_screen.dart';
import 'package:journal_app/features/library/journal_library_view.dart';
import 'package:journal_app/features/library/theme_picker_dialog.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';

import 'package:journal_app/core/services/deep_link_service.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/l10n/app_localizations.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const int _tabCount = 5;
  static const int _homeTabIndex = 2;

  int _selectedIndex = _homeTabIndex;
  late final PageController _pageController;
  StreamSubscription<NotificationTapIntent>? _notificationTapSubscription;
  final Set<String> _handledTapIds = <String>{};
  DeepLinkService? _deepLinkService;
  NotificationService? _notificationService;

  final _titles = [
    'Günlüklerim', // 0
    'Çıkartmalar', // 1
    'Anasayfa', // 2
    'Arkadaşlar', // 3
    'Profil ve Ayarlar', // 4
  ];

  String get _currentTitle {
    if (_selectedIndex >= 0 && _selectedIndex < _titles.length) {
      return _titles[_selectedIndex];
    }
    return _titles[_homeTabIndex];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _deepLinkService = ref.read(deepLinkServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);

    // Initialize deep link listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final initFuture = _deepLinkService?.init(context);
      if (initFuture != null) {
        unawaited(initFuture);
      }
      _bindNotificationTapListener();
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    _deepLinkService?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _bindNotificationTapListener() {
    final notificationService = _notificationService;
    if (notificationService == null) {
      return;
    }
    final pendingIntent = notificationService.takePendingTapIntent();
    if (pendingIntent != null) {
      unawaited(_handleNotificationTapIntent(pendingIntent));
    }

    _notificationTapSubscription = notificationService.notificationTapStream
        .listen((intent) {
          unawaited(_handleNotificationTapIntent(intent));
        });
  }

  Future<void> _handleNotificationTapIntent(
    NotificationTapIntent intent,
  ) async {
    final notificationId = intent.notificationId;
    if (notificationId.isNotEmpty && _handledTapIds.contains(notificationId)) {
      return;
    }
    if (notificationId.isNotEmpty) {
      _handledTapIds.add(notificationId);
    }

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null && notificationId.isNotEmpty) {
      await ref
          .read(notificationServiceProvider)
          .markNotificationRead(uid: uid, notificationId: notificationId);
    }

    final isFirebaseAvailable = ref.read(firebaseAvailableProvider);
    if (isFirebaseAvailable) {
      await NotificationService.logEvent(
        'push_opened',
        parameters: {'type': intent.type},
      );
    }

    if (!mounted) {
      return;
    }

    final route = intent.route.isNotEmpty ? intent.route : '/notifications';
    if (route == '/notifications') {
      context.push('/notifications');
      return;
    }
    context.push(route);
  }

  void _onItemTapped(int index) {
    final targetIndex = index.clamp(0, _tabCount - 1);
    if (targetIndex == _selectedIndex) {
      return;
    }

    final currentIndex = _selectedIndex;
    setState(() {
      _selectedIndex = targetIndex;
    });

    if (!_pageController.hasClients) {
      return;
    }

    final distance = (targetIndex - currentIndex).abs();
    if (distance > 1) {
      _pageController.jumpToPage(targetIndex);
      return;
    }

    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final targetIndex = index.clamp(0, _tabCount - 1);
    if (targetIndex == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = targetIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Çıkartma Ekle',
              onPressed: () => context.push('/stickers/create'),
            ),
          IconButton(
            icon: const Icon(Icons.inbox_rounded),
            tooltip: 'Inbox',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: const [
          JournalLibraryView(), // 0
          StickerManagerView(), // 1
          HomeScreen(), // 2
          FriendsView(), // 3
          ProfileSettingsView(), // 4
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex ==
              0 // Only show FAB on Journals tab (Index 0)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FloatingActionButton(
                onPressed: () => _showCreateDialog(context, ref),
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  // Removed _onItemTapped as it's replaced by onDestinationSelected inline

  // --- Create Dialog Logic (Moved locally or duplicated) ---
  // Ideally this should be in JournalLibraryView but FAB is usually on Scaffold.
  // We can keep it here for now.

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String selectedThemeId = 'default';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedTheme = NostalgicThemes.getById(selectedThemeId);
          final useDarkText =
              selectedTheme.visuals.coverGradient.first.computeLuminance() >
              0.56;
          final coverTextColor = useDarkText
              ? BrandColors.primary900
              : Colors.white;

          return AlertDialog(
            title: Text(l10n.libraryCreateTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.libraryRenameHint,
                    hintText: l10n.libraryCreateHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.libraryThemePickerTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                        colors: selectedTheme.visuals.coverGradient,
                      ),
                      image: selectedTheme.visuals.assetPath != null
                          ? DecorationImage(
                              image: AssetImage(
                                selectedTheme.visuals.assetPath!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selectedTheme.visuals.assetPath == null)
                          Text(
                            selectedTheme.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: coverTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          selectedTheme.name,
                          style: TextStyle(
                            color: coverTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_drop_down, color: coverTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
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
                child: Text(l10n.libraryCreateAction),
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
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context);

    // Use the provider which handles ownerId and cloud sync
    final createJournal = ref.read(createJournalProvider);

    try {
      await createJournal(title: title, coverStyle: themeId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.errorPrefix ?? 'Error'}: $e')),
        );
      }
    }
  }
}
