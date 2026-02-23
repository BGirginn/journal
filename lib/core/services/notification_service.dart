import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/device/device_identity.dart';
import 'package:journal_app/core/localization/locale_provider.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationTapIntent {
  const NotificationTapIntent({
    required this.notificationId,
    required this.type,
    required this.route,
    required this.inviteId,
    required this.targetId,
  });

  final String notificationId;
  final String type;
  final String route;
  final String? inviteId;
  final String? targetId;

  factory NotificationTapIntent.fromData(Map<String, dynamic> data) {
    return NotificationTapIntent(
      notificationId: data['notificationId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'unknown',
      route: data['route']?.toString() ?? '/notifications',
      inviteId: data['inviteId']?.toString(),
      targetId: data['targetId']?.toString(),
    );
  }
}

/// Push notification service using Firebase Cloud Messaging.
class NotificationService {
  NotificationService({
    required SharedPreferences prefs,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    bool isFirebaseAvailable = true,
  }) : _prefs = prefs,
       _messaging =
           messaging ??
           (isFirebaseAvailable ? FirebaseMessaging.instance : null),
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? (isFirebaseAvailable ? FirebaseAuth.instance : null),
       _isFirebaseAvailable = isFirebaseAvailable;

  final SharedPreferences _prefs;
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final bool _isFirebaseAvailable;

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  static const AndroidNotificationChannel _invitesChannel =
      AndroidNotificationChannel(
        'invites',
        'Invites',
        description: 'Invite notifications',
        importance: Importance.high,
      );

  final StreamController<NotificationTapIntent> _tapController =
      StreamController<NotificationTapIntent>.broadcast();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;

  bool _initialized = false;
  NotificationTapIntent? _pendingTapIntent;

  Stream<NotificationTapIntent> get notificationTapStream =>
      _tapController.stream;

  NotificationTapIntent? takePendingTapIntent() {
    final pending = _pendingTapIntent;
    _pendingTapIntent = null;
    return pending;
  }

  /// Initialize FCM, local notifications, Analytics, and Crashlytics.
  Future<void> init() async {
    if (_initialized || !_isFirebaseAvailable) {
      return;
    }
    _initialized = true;

    await _initializeLocalNotifications();
    await _initializeMessaging();
    _initializeCrashlytics();
    await _bindUserTracking();
  }

  Future<void> _initializeMessaging() async {
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _emitTapIntentFromData(initialMessage.data);
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await registerOrUpdatePushToken();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((_) {
        registerOrUpdatePushToken();
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        try {
          final parsed = jsonDecode(payload);
          if (parsed is Map<String, dynamic>) {
            _emitTapIntentFromData(parsed);
          }
        } catch (error) {
          debugPrint('Failed to parse local notification payload: $error');
        }
      },
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_invitesChannel);
  }

  void _initializeCrashlytics() {
    FlutterError.onError = (errorDetails) {
      crashlytics.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> _bindUserTracking() async {
    final auth = _auth;
    if (auth == null) {
      return;
    }

    _authSubscription = auth.authStateChanges().listen((user) async {
      if (user == null) {
        await analytics.setUserId(id: null);
        await crashlytics.setUserIdentifier('');
        return;
      }

      await analytics.setUserId(id: user.uid);
      await crashlytics.setUserIdentifier(user.uid);
      await registerOrUpdatePushToken();
    });

    final currentUser = auth.currentUser;
    if (currentUser != null) {
      await analytics.setUserId(id: currentUser.uid);
      await crashlytics.setUserIdentifier(currentUser.uid);
    }
  }

  Future<void> registerOrUpdatePushToken() async {
    if (!_isFirebaseAvailable) {
      return;
    }

    final auth = _auth;
    final messaging = _messaging;
    if (auth == null || messaging == null) {
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final uid = user.uid;
    final deviceId = getOrCreateSyncDeviceId(_prefs);
    final preferredLanguage = _resolvePreferredLanguage();

    final userDoc = _firestore.collection(FirestorePaths.users).doc(uid);
    await userDoc.collection(FirestorePaths.pushTokens).doc(deviceId).set({
      'token': token,
      'platform': _platformName(),
      'preferredLanguage': preferredLanguage,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep a one-release backward compatible write path without creating
    // placeholder user documents before profile setup.
    try {
      await userDoc.update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'preferredLanguage': preferredLanguage,
      });
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') {
        rethrow;
      }
    }
  }

  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  }) async {
    if (notificationId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.notifications)
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (error) {
      debugPrint('markNotificationRead failed for $notificationId: $error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await NotificationService.logEvent(
      'push_received_foreground',
      parameters: {'type': message.data['type']?.toString() ?? 'unknown'},
    );

    final title = message.notification?.title ?? 'Journal';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _invitesChannel.id,
          _invitesChannel.name,
          channelDescription: _invitesChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(_toSerializableMap(message.data)),
    );
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    await NotificationService.logEvent(
      'push_opened',
      parameters: {'type': message.data['type']?.toString() ?? 'unknown'},
    );
    _emitTapIntentFromData(message.data);
  }

  void _emitTapIntentFromData(Map<String, dynamic> data) {
    final intent = NotificationTapIntent.fromData(data);
    if (intent.notificationId.isEmpty) {
      return;
    }

    if (!_tapController.hasListener) {
      _pendingTapIntent = intent;
    }
    _tapController.add(intent);
  }

  String _resolvePreferredLanguage() {
    final persisted = _prefs.getString(appLocaleCodePreferenceKey);
    final raw = (persisted ?? PlatformDispatcher.instance.locale.languageCode)
        .toLowerCase();
    if (raw.startsWith('en')) {
      return 'en';
    }
    if (raw.startsWith('tr')) {
      return 'tr';
    }
    return 'tr';
  }

  static Map<String, dynamic> _toSerializableMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    input.forEach((key, value) {
      if (value == null || value is num || value is bool || value is String) {
        result[key] = value;
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
    await _tapController.close();
  }

  /// Log analytics event.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log screen view.
  static Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final isFirebaseAvailable = ref.watch(firebaseAvailableProvider);
  final service = NotificationService(
    prefs: prefs,
    isFirebaseAvailable: isFirebaseAvailable,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
