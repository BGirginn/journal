import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/features/library/library_screen.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/team/screens/team_list_screen.dart';
import 'package:journal_app/features/team/screens/team_management_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_manager_screen.dart';
import 'package:journal_app/features/stickers/screens/sticker_creator_screen.dart';

import 'package:journal_app/core/sync/sync_service.dart';
import 'package:journal_app/core/auth/user_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // We use a ValueNotifier to notify GoRouter when auth state changes
  // Ideally we would wrap the Stream in a ChangeNotifier or similar.
  // For simplicity, we can force rebuild if main.dart rebuilds, but that's bad.
  // Better: Create a notifier that listens to the stream.

  final authNotifier = ValueNotifier<bool>(false);

  ref.listen(authStateProvider, (_, next) {
    // Determine if logged in (user is not null)
    final isLoggedIn = next.value != null;
    if (authNotifier.value != isLoggedIn) {
      authNotifier.value = isLoggedIn;
      // GoRouter will listen to this notifier

      // Trigger sync and profile check on login
      if (isLoggedIn) {
        ref.read(syncServiceProvider).syncDown();
        ref.read(userServiceProvider).ensureProfileExists();
      }
    }
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value != null;
      final isGuest = ref.read(guestModeProvider);

      final canAccess = isLoggedIn || isGuest;

      final isLoginRoute = state.uri.path == '/login';

      if (!canAccess && !isLoginRoute) return '/login';
      if (canAccess && isLoginRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LibraryScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
