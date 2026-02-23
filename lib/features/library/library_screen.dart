import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:journal_app/providers/providers.dart';

/// Library screen - displays list of journals
import 'package:journal_app/features/home/home_screen.dart';
import 'package:journal_app/features/friends/friends_screen.dart';
import 'package:journal_app/features/library/journal_library_view.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';

import 'package:journal_app/core/services/deep_link_service.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final int? initialTab;

  const LibraryScreen({super.key, this.initialTab});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const int _tabCount = 5;
  static const int _homeTabIndex = 2;
  static const double _fabGapFromBottomBar = 40;

  late int _selectedIndex;
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
    _selectedIndex = (widget.initialTab ?? _homeTabIndex).clamp(
      0,
      _tabCount - 1,
    );
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
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = (widget.initialTab ?? _homeTabIndex).clamp(
      0,
      _tabCount - 1,
    );
    if (nextIndex == _selectedIndex) {
      return;
    }
    _selectedIndex = nextIndex;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(nextIndex);
    }
    setState(() {});
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
    final durationMs = (150 + (distance * 50)).clamp(150, 350);
    _pageController.animateToPage(
      targetIndex,
      duration: Duration(milliseconds: durationMs),
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

  Future<void> _showCreateJournalDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.libraryCreateTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(dialogContext, value);
            }
          },
          decoration: InputDecoration(hintText: l10n.libraryCreateHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: Text(l10n.libraryCreateAction),
          ),
        ],
      ),
    );

    if (!mounted || title == null || title.trim().isEmpty) {
      return;
    }

    try {
      final createJournal = ref.read(createJournalProvider);
      final journal = await createJournal(title: title.trim());
      if (!mounted) {
        return;
      }
      context.push('/journal/${journal.id}');
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Günlük oluşturulamadı: $e')));
    }
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
          IconButton(
            icon: const Icon(LucideIcons.inbox),
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
          StickerManagerView(isEmbeddedInLibrary: true), // 1
          HomeScreen(isEmbeddedInLibrary: true), // 2
          FriendsView(), // 3
          ProfileSettingsView(), // 4
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
      floatingActionButtonLocation: _selectedIndex == 0
          ? const _FabAboveBottomBarLocation(gap: _fabGapFromBottomBar)
          : null,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreateJournalDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _FabAboveBottomBarLocation extends FloatingActionButtonLocation {
  final double gap;

  const _FabAboveBottomBarLocation({required this.gap});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final bottomInset = scaffoldGeometry.minInsets.bottom;
    final barTop =
        scaffoldGeometry.scaffoldSize.height -
        bottomInset -
        CustomBottomNavigation.kBarBottomInset -
        CustomBottomNavigation.kBarHeight;
    final y = barTop - fabSize.height - gap;
    const horizontalMargin = 16.0;

    final x = switch (scaffoldGeometry.textDirection) {
      TextDirection.rtl => scaffoldGeometry.minInsets.left + horizontalMargin,
      TextDirection.ltr =>
        scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.minInsets.right -
            horizontalMargin -
            fabSize.width,
    };

    return Offset(x, y);
  }
}
