import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:journal_app/core/theme/app_theme.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/features/library/library_screen.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/sync/sync_service.dart';
import 'firebase_options.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase (Requires google-services.json / GoogleService-Info.plist)
  bool isFirebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseAvailable = true;
  } catch (e) {
    debugPrint('Firebase Init Failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: JournalApp(isFirebaseAvailable: isFirebaseAvailable),
    ),
  );
}

class JournalApp extends ConsumerWidget {
  final bool isFirebaseAvailable;

  const JournalApp({super.key, required this.isFirebaseAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize provider synchronously
    Future.microtask(
      () => ref.read(firebaseAvailableProvider.notifier).state =
          isFirebaseAvailable,
    );

    final themeSettings = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Journal V2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(AppColorTheme.purple, Brightness.light),
      darkTheme: AppTheme.getTheme(AppColorTheme.purple, Brightness.dark),
      themeMode: themeSettings.mode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(guestModeProvider);

    return authState.when(
      data: (user) {
        if (user != null || isGuest) {
          // Trigger sync if not guest (or both if we want guest sync? no, guest has no uid)
          if (!isGuest && user != null) {
            Future.microtask(() => ref.read(syncServiceProvider).syncDown());
          }
          return const LibraryScreen();
        }
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
