import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/features/auth/profile_setup_screen.dart';
import 'package:journal_app/features/library/library_screen.dart';
import 'package:journal_app/features/onboarding/onboarding_screen.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/team/screens/team_list_screen.dart';
import 'package:journal_app/features/team/screens/team_management_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_creator_screen.dart';
import 'package:journal_app/features/notifications/notifications_screen.dart';

import 'package:journal_app/core/sync/sync_service.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';
import 'package:journal_app/providers/journal_providers.dart';

/// Provider to track if user needs profile setup
final needsProfileSetupProvider = StateProvider<bool?>((ref) => null);
final onboardingCompletedProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('onboarding_complete') ?? false;
});

int parseRootTabFromUri(Uri uri, {int fallback = 2}) {
  final raw = uri.queryParameters['tab'];
  final parsed = int.tryParse(raw ?? '');
  return parsed ?? fallback;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  final profileNotifier = ValueNotifier<bool?>(null);

  ref.listen(authStateProvider, (_, next) {
    final isLoggedIn = next.value != null;
    if (authNotifier.value != isLoggedIn) {
      authNotifier.value = isLoggedIn;

      if (isLoggedIn) {
        final syncService = ref.read(syncServiceProvider);
        syncService.syncDown();
        syncService.startSyncLoop();
        // First-time users need profile setup; existing users continue directly.
        ref
            .read(userServiceProvider)
            .ensureProfileExistsAndNeedsSetup()
            .then((needsSetup) {
              ref.read(needsProfileSetupProvider.notifier).state = needsSetup;
              if (profileNotifier.value != needsSetup) {
                profileNotifier.value = needsSetup;
              }
            })
            .catchError((e) {
              debugPrint('Profile check failed: $e');
              // Fail open to prevent login deadlock.
              ref.read(needsProfileSetupProvider.notifier).state = false;
              profileNotifier.value = false;
            });
      } else {
        // User logged out - reset profile setup state for next user
        ref.read(syncServiceProvider).stopSyncLoop();
        ref.read(needsProfileSetupProvider.notifier).state = null;
        profileNotifier.value = null;
      }
    }
  }, fireImmediately: true);

  // Listen to profile stream for changes
  ref.listen(myProfileProvider, (_, next) {
    final profile = next.value;
    if (profile != null) {
      final current = ref.read(needsProfileSetupProvider);
      // Only clear setup state when profile becomes complete.
      // Do not force users back to setup for legacy/incomplete profile flags.
      if (current == true && profile.isProfileComplete) {
        ref.read(needsProfileSetupProvider.notifier).state = false;
        profileNotifier.value = false;
      }
    }
  });

  // Also listen to the state provider directly, in case it's updated manually
  ref.listen<bool?>(needsProfileSetupProvider, (_, next) {
    // Keep notifier aligned with provider so router refreshes on pending/ready transitions.
    profileNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([authNotifier, profileNotifier]),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      final needsProfileSetup = ref.read(needsProfileSetupProvider);
      final onboardingCompleted = ref.read(onboardingCompletedProvider);

      final isLoginRoute = state.uri.path == '/login';
      final isProfileSetupRoute = state.uri.path == '/profile-setup';
      final isOnboardingRoute = state.uri.path == '/onboarding';

      if (!isLoggedIn) {
        if (!onboardingCompleted && !isOnboardingRoute) return '/onboarding';
        if (onboardingCompleted && isOnboardingRoute) return '/login';
        if (onboardingCompleted && !isLoginRoute && !isOnboardingRoute) {
          return '/login';
        }
      }

      // Logged in but on login page -> redirect
      if (isLoggedIn && isLoginRoute) {
        // Check if needs profile setup
        if (needsProfileSetup == true) return '/profile-setup';

        // If profile check is still pending (null), stay here (effectively loading)
        // Only go to home if explicitly false
        if (needsProfileSetup == false) return '/';

        return null; // Stay on login if checking
      }

      // Logged in, needs setup (or unknown), not on setup page -> redirect
      if (isLoggedIn && !isProfileSetupRoute) {
        if (needsProfileSetup == true) return '/profile-setup';
        // If unknown (null), go back to login (loading state)
        if (needsProfileSetup == null) return '/login';
      }

      // Profile complete but on setup page -> go home
      if (isLoggedIn && needsProfileSetup == false && isProfileSetupRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            LibraryScreen(initialTab: parseRootTabFromUri(state.uri)),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () async {
            final prefs = ref.read(sharedPreferencesProvider);
            await prefs.setBool('onboarding_complete', true);
            ref.read(onboardingCompletedProvider.notifier).state = true;
            if (context.mounted) context.go('/login');
          },
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => const TeamListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                TeamManagementScreen(teamId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/stickers',
        builder: (context, state) => const StickerManagerScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const StickerCreatorScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/journal/:id',
        builder: (context, state) {
          final journalId = state.pathParameters['id']!;
          // We need to fetch the journal object. Since we don't have it synchronously,
          // we might need a wrapper or look it up.
          // For now, let's assume we can pass a provider or use a wrapper screen.
          // BUT JournalViewScreen requires a Journal object.
          // We can use a "JournalLoaderScreen" or modify JournalViewScreen to take ID.
          return JournalLoaderScreen(journalId: journalId);
        },
      ),
    ],
  );
});

class JournalLoaderScreen extends ConsumerWidget {
  final String journalId;
  const JournalLoaderScreen({super.key, required this.journalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalProvider(journalId));

    return journalAsync.when(
      data: (journal) {
        if (journal == null) {
          return const Scaffold(body: Center(child: Text('Günlük bulunamadı')));
        }
        return JournalViewScreen(journal: journal);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Günlük bulunamadı: $e'))),
    );
  }
}
