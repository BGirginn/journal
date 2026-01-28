import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/features/auth/profile_setup_screen.dart';
import 'package:journal_app/features/library/library_screen.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/team/screens/team_list_screen.dart';
import 'package:journal_app/features/team/screens/team_management_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_creator_screen.dart';

import 'package:journal_app/core/sync/sync_service.dart';
import 'package:journal_app/core/auth/user_service.dart';

/// Provider to track if user needs profile setup
final needsProfileSetupProvider = StateProvider<bool?>((ref) => null);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  final profileNotifier = ValueNotifier<bool>(false);

  ref.listen(authStateProvider, (_, next) {
    final isLoggedIn = next.value != null;
    if (authNotifier.value != isLoggedIn) {
      authNotifier.value = isLoggedIn;

      if (isLoggedIn) {
        ref.read(syncServiceProvider).syncDown();
        // Check profile and update needsProfileSetup
        ref
            .read(userServiceProvider)
            .ensureProfileExists()
            .then((profile) {
              if (profile != null) {
                final needsSetup = !profile.isProfileComplete;
                ref.read(needsProfileSetupProvider.notifier).state = needsSetup;
                if (profileNotifier.value != needsSetup) {
                  profileNotifier.value = needsSetup;
                }
              } else {
                // Profile is null (e.g., Firebase unavailable) - assume needs setup
                ref.read(needsProfileSetupProvider.notifier).state = true;
                profileNotifier.value = true;
              }
            })
            .catchError((e) {
              // On error, default to needing profile setup to avoid stuck state
              debugPrint('Profile check failed: $e');
              ref.read(needsProfileSetupProvider.notifier).state = true;
              profileNotifier.value = true;
            });
      }
    }
  });

  // Listen to profile stream for changes
  ref.listen(myProfileProvider, (_, next) {
    final profile = next.value;
    if (profile != null) {
      final needsSetup = !profile.isProfileComplete;
      final current = ref.read(needsProfileSetupProvider);
      if (current != needsSetup) {
        ref.read(needsProfileSetupProvider.notifier).state = needsSetup;
        profileNotifier.value = needsSetup;
      }
    }
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([authNotifier, profileNotifier]),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      final isGuest = ref.read(guestModeProvider);
      final needsProfileSetup = ref.read(needsProfileSetupProvider);

      final canAccess = isLoggedIn || isGuest;
      final isLoginRoute = state.uri.path == '/login';
      final isProfileSetupRoute = state.uri.path == '/profile-setup';

      // Not logged in -> login
      if (!canAccess && !isLoginRoute) return '/login';

      // Logged in but on login page -> redirect
      if (canAccess && isLoginRoute) {
        // Check if needs profile setup
        if (needsProfileSetup == true) return '/profile-setup';

        // If profile check is still pending (null), stay here (effectively loading)
        // Only go to home if explicitly false
        if (needsProfileSetup == false) return '/';

        return null; // Stay on login if checking
      }

      // Logged in, needs setup (or unknown), not on setup page -> redirect
      if (canAccess && !isGuest && !isProfileSetupRoute) {
        if (needsProfileSetup == true) return '/profile-setup';
        // If unknown (null), go back to login (loading state)
        if (needsProfileSetup == null) return '/login';
      }

      // Profile complete but on setup page -> go home
      if (canAccess && needsProfileSetup == false && isProfileSetupRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LibraryScreen()),
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
    ],
  );
});
