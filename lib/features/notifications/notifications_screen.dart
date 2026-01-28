import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/auth/user_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteService = ref.watch(inviteServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: StreamBuilder<List<Invite>>(
        stream: inviteService.watchMyInvites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invites = snapshot.data ?? [];

          if (invites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Henüz bir bildirim yok.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _InviteTile(invite: invites[index]);
            },
          );
        },
      ),
    );
  }
}

class _InviteTile extends ConsumerStatefulWidget {
  final Invite invite;

  const _InviteTile({required this.invite});

  @override
  ConsumerState<_InviteTile> createState() => _InviteTileState();
}

class _InviteTileState extends ConsumerState<_InviteTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final typeName = invite.type == InviteType.team
        ? 'Takım Daveti'
        : 'Günlük Daveti';

    // Fetch inviter name
    final inviterFuture = ref
        .read(userServiceProvider)
        .getUserProfile(invite.inviterId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<UserProfile?>(
              future: inviterFuture,
              builder: (context, snapshot) {
                final name =
                    snapshot.data?.displayName ?? 'Bilinmeyen Kullanıcı';
                return Text('$name sizi davet ediyor.');
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Rol: ${invite.role.displayName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => _respond(false),
                  child: const Text(
                    'Reddet',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : () => _respond(true),
                  child: const Text('Kabul Et'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(bool accept) async {
    setState(() => _isLoading = true);
    try {
      if (accept) {
        await ref.read(inviteServiceProvider).acceptInvite(widget.invite);
      } else {
        await ref.read(inviteServiceProvider).rejectInvite(widget.invite);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Davet kabul edildi.' : 'Davet reddedildi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
