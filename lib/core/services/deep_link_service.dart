import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journal_app/core/database/firestore_paths.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/observability/app_logger.dart';
import 'package:journal_app/core/observability/telemetry_service.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/features/invite/invite_service.dart';

/// Deep link service for handling invite links and universal links
/// Link format: journalapp://invite/{inviteId}
class DeepLinkService {
  final Ref ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;
  bool _initialized = false;

  DeepLinkService(this.ref);

  /// Initialize deep link listener
  Future<void> init(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    // Check initial link (app was opened via link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && context.mounted) {
        _handleUri(initialUri, context);
      }
    } catch (e, st) {
      _reportDeepLinkError(
        operation: 'get_initial_link',
        error: e,
        stackTrace: st,
      );
    }

    // Listen for incoming links while app is running
    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (context.mounted) {
          _handleUri(uri, context);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _reportDeepLinkError(
          operation: 'stream_link',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  void _handleUri(Uri uri, BuildContext context) {
    final leadSegment = (uri.host == 'invite' || uri.host == 'journal')
        ? uri.host
        : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : uri.host);

    if (leadSegment == 'invite') {
      final inviteId = uri.pathSegments.isNotEmpty && uri.host == 'invite'
          ? uri.pathSegments.first
          : (uri.pathSegments.length >= 2 ? uri.pathSegments[1] : null);
      if (inviteId != null && inviteId.isNotEmpty) {
        _handleInviteLink(inviteId, context);
      }
    }

    if (leadSegment == 'journal') {
      final journalId = uri.pathSegments.isNotEmpty && uri.host == 'journal'
          ? uri.pathSegments.first
          : (uri.pathSegments.length >= 2 ? uri.pathSegments[1] : null);
      if (journalId != null && journalId.isNotEmpty) {
        if (context.mounted) context.push('/journal/$journalId');
      }
    }
  }

  Future<void> _handleInviteLink(String inviteId, BuildContext context) async {
    try {
      // Fetch the invite document from Firestore
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.invites)
          .doc(inviteId)
          .get();

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Davet bulunamadı veya süresi dolmuş'),
            ),
          );
        }
        return;
      }

      final data = doc.data()!;
      final invite = Invite(
        id: doc.id,
        type: InviteType.values.firstWhere(
          (e) => e.name == (data['type'] ?? 'team'),
          orElse: () => InviteType.team,
        ),
        targetId: data['targetId'] ?? '',
        inviterId: data['inviterId'] ?? '',
        inviteeId: data['inviteeId'],
        status: InviteStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'pending'),
          orElse: () => InviteStatus.pending,
        ),
        role: JournalRole.values.firstWhere(
          (e) => e.name == (data['role'] ?? 'editor'),
          orElse: () => JournalRole.editor,
        ),
        expiresAt:
            (data['expiresAt'] as Timestamp?)?.toDate() ??
            DateTime.now().add(const Duration(days: 7)),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );

      final inviteService = ref.read(inviteServiceProvider);
      await inviteService.acceptInvite(invite);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Davet kabul edildi! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/notifications');
      }
    } catch (e, st) {
      _reportDeepLinkError(
        operation: 'handle_invite_link',
        error: e,
        stackTrace: st,
        extra: {'invite_id': inviteId},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Davet hatası: $e')));
      }
    }
  }

  /// Generate invite link for sharing
  static String generateInviteLink(String inviteId) {
    return 'https://journalapp.page.link/invite/$inviteId';
  }

  void _reportDeepLinkError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    final typed = SyncError(
      code: 'deep_link_$operation',
      message: 'Deep link operation failed: $operation',
      cause: error,
      stackTrace: stackTrace,
    );
    ref
        .read(appLoggerProvider)
        .warn(
          'deep_link_error',
          data: {'operation': operation, ...extra},
          error: typed,
          stackTrace: stackTrace,
        );
    ref
        .read(telemetryServiceProvider)
        .track(
          'deep_link_error',
          params: {'operation': operation, 'error_code': typed.code, ...extra},
        );
  }

  void dispose() {
    _initialized = false;
    _sub?.cancel();
    _sub = null;
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(ref);
  ref.onDispose(service.dispose);
  return service;
});
