import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/features/notifications/models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final isAvailable = ref.watch(firebaseAvailableProvider);
  return NotificationsRepository(
    firestore: isAvailable ? FirebaseFirestore.instance : null,
  );
});

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref.watch(notificationsRepositoryProvider).watchNotifications(uid);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) {
    return Stream.value(0);
  }
  return ref.watch(notificationsRepositoryProvider).watchUnreadCount(uid);
});

class NotificationsRepository {
  NotificationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Stream<List<AppNotification>> watchNotifications(String uid) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(const <AppNotification>[]);
    }

    final stream = firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.notifications)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(growable: false),
        );
    return _fallbackOnPermissionDenied(
      stream,
      fallback: const <AppNotification>[],
      context: 'watchNotifications',
    );
  }

  Stream<int> watchUnreadCount(String uid) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(0);
    }

    final stream = firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.notifications)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
    return _fallbackOnPermissionDenied(
      stream,
      fallback: 0,
      context: 'watchUnreadCount',
    );
  }

  Stream<T> _fallbackOnPermissionDenied<T>(
    Stream<T> stream, {
    required T fallback,
    required String context,
  }) {
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            debugPrint(
              'NotificationsRepository.$context permission denied: ${error.message}',
            );
            sink.add(fallback);
            return;
          }
          sink.addError(error, stackTrace);
        },
      ),
    );
  }
}
