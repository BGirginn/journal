import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/services/notification_service.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/features/notifications/models/app_notification.dart';
import 'package:journal_app/features/notifications/notifications_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _NotificationsAppBar(),
      body: NotificationsView(),
    );
  }
}

class _NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _NotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Bildirimler'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  final Set<String> _loadingActionIds = <String>{};

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) {
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      return;
    }

    await ref
        .read(notificationServiceProvider)
        .markNotificationRead(uid: uid, notificationId: notification.id);
    final isFirebaseAvailable = ref.read(firebaseAvailableProvider);
    if (isFirebaseAvailable) {
      await NotificationService.logEvent(
        'notification_marked_read',
        parameters: {'notification_type': notification.type.name},
      );
    }
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    await _markRead(notification);
    if (!mounted) {
      return;
    }
    if (notification.route != '/notifications') {
      context.push(notification.route);
    }
  }

  Future<void> _respondToInvite(
    AppNotification notification,
    bool accept,
  ) async {
    final inviteId = notification.inviteId;
    if (inviteId == null || inviteId.isEmpty) {
      return;
    }

    setState(() => _loadingActionIds.add(notification.id));
    try {
      final inviteService = ref.read(inviteServiceProvider);
      final invite = await inviteService.fetchInviteById(inviteId);
      if (invite == null) {
        await _markRead(notification);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Davet artık bulunamadı.')),
        );
        return;
      }

      if (invite.status != InviteStatus.pending) {
        await _markRead(notification);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu davet daha önce işlenmiş.')),
        );
        return;
      }

      if (accept) {
        await inviteService.acceptInvite(invite);
      } else {
        await inviteService.rejectInvite(invite);
      }

      await _markRead(notification);
      final isFirebaseAvailable = ref.read(firebaseAvailableProvider);
      if (isFirebaseAvailable) {
        await NotificationService.logEvent(
          'invite_notification_action',
          parameters: {'action': accept ? 'accept' : 'reject'},
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Davet kabul edildi.' : 'Davet reddedildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
    } finally {
      if (mounted) {
        setState(() => _loadingActionIds.remove(notification.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const _EmptyNotifications();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (context, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isActionLoading = _loadingActionIds.contains(notification.id);
            return _NotificationTile(
              notification: notification,
              isActionLoading: isActionLoading,
              onTap: () => _onNotificationTap(notification),
              onAccept: notification.type == AppNotificationType.inviteReceived
                  ? () => _respondToInvite(notification, true)
                  : null,
              onReject: notification.type == AppNotificationType.inviteReceived
                  ? () => _respondToInvite(notification, false)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Bildirimler yüklenemedi: $error'),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz bir bildirim yok.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isActionLoading,
    required this.onTap,
    this.onAccept,
    this.onReject,
  });

  final AppNotification notification;
  final bool isActionLoading;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (notification.type) {
      AppNotificationType.inviteReceived => Icons.mail_outline,
      AppNotificationType.inviteAccepted => Icons.check_circle_outline,
      AppNotificationType.inviteRejected => Icons.cancel_outlined,
      AppNotificationType.unknown => Icons.notifications_outlined,
    };

    final iconColor = switch (notification.type) {
      AppNotificationType.inviteReceived => colorScheme.primary,
      AppNotificationType.inviteAccepted => Colors.green,
      AppNotificationType.inviteRejected => colorScheme.error,
      AppNotificationType.unknown => colorScheme.onSurfaceVariant,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? colorScheme.surfaceContainerLow
                : colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isRead
                  ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                  : colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(notification.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onAccept != null && onReject != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isActionLoading ? null : onReject,
                      child: const Text('Reddet'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: isActionLoading ? null : onAccept,
                      child: isActionLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kabul Et'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final twoDigitsHour = local.hour.toString().padLeft(2, '0');
    final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
    final twoDigitsDay = local.day.toString().padLeft(2, '0');
    final twoDigitsMonth = local.month.toString().padLeft(2, '0');
    return '$twoDigitsDay.$twoDigitsMonth.${local.year} $twoDigitsHour:$twoDigitsMinute';
  }
}
