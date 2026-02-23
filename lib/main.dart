import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as import_firebase_auth;
import 'package:journal_app/core/theme/app_theme.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/localization/locale_provider.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/services/notification_service.dart';

void main() async {
  debugPaintSizeEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase (Requires google-services.json / GoogleService-Info.plist)
  bool isFirebaseAvailable = false;
  String? firebaseError;
  try {
    // Add a tiny delay to ensure engine is fully ready for channel communication
    await Future.delayed(const Duration(milliseconds: 100));
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseAvailable = true;
  } catch (e) {
    debugPrint('Firebase Init Failed: $e');
    if (e is PlatformException && e.code == 'channel-error') {
      firebaseError =
          'Native bağlantı hatası: Lütfen uygulamayı tamamen durdurup "flutter clean" sonrası yeniden başlatın.';
    } else {
      firebaseError = e.toString();
    }
  }

  // Check for first run and clear lingering auth tokens if necessary
  if (isFirebaseAvailable) {
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    if (isFirstRun) {
      try {
        await import_firebase_auth.FirebaseAuth.instance.signOut();
        await prefs.setBool('is_first_run', false);
        debugPrint('First run detected: Signed out any existing session.');
      } catch (e) {
        debugPrint('Error signing out on first run: $e');
      }
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseAvailableProvider.overrideWith((ref) => isFirebaseAvailable),
        firebaseErrorProvider.overrideWith((ref) => firebaseError),
      ],
      child: const JournalApp(),
    ),
  );
}

class JournalApp extends ConsumerStatefulWidget {
  const JournalApp({super.key});

  @override
  ConsumerState<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends ConsumerState<JournalApp> {
  bool _notificationInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationServiceIfNeeded();
    });
  }

  void _initNotificationServiceIfNeeded() {
    if (_notificationInitialized) {
      return;
    }
    final isFirebaseAvailable = ref.read(firebaseAvailableProvider);
    if (!isFirebaseAvailable) {
      return;
    }

    _notificationInitialized = true;
    unawaited(
      Future<void>(() async {
        try {
          await ref.read(notificationServiceProvider).init();
          debugPrint('Notification/Analytics/Crashlytics initialized.');
        } catch (e) {
          debugPrint('Notification/Analytics init failed: $e');
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        Brightness.light,
        variant: themeSettings.effectiveVariant,
      ),
      darkTheme: AppTheme.getTheme(
        Brightness.dark,
        variant: themeSettings.effectiveVariant,
      ),
      themeMode: themeSettings.mode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
