import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journal_app/core/database/firestore_paths.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (no UI access)
  debugPrint('Background message: ${message.notification?.title}');
}

/// Push notification service using Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  /// Initialize FCM, Analytics, and Crashlytics
  Future<void> init() async {
    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
    }

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Setup message open handler (when tapping notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Initialize Crashlytics
    FlutterError.onError = (errorDetails) {
      crashlytics.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Set user ID for analytics and crashlytics
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await analytics.setUserId(id: user.uid);
      await crashlytics.setUserIdentifier(user.uid);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // You could show an in-app notification banner here
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Opened app via notification: ${message.data}');
    // Navigate based on message data
    final type = message.data['type'];
    if (type == 'invite') {
      // Navigate to notifications screen
    } else if (type == 'journal_update') {
      // Navigate to specific journal
    }
  }

  /// Send local notification for invite (called from InviteService)
  Future<void> sendInviteNotification({
    required String targetUserId,
    required String senderName,
    required String teamName,
  }) async {
    // In production, this would trigger a Cloud Function
    // that sends FCM to the target user's device
    debugPrint(
      'Would send push to $targetUserId: '
      '$senderName sizi "$teamName" ekibine davet etti',
    );
  }

  /// Log analytics event
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log screen view
  static Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
