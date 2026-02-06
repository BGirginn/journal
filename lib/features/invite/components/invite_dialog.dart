import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/core/auth/user_service.dart';

class InviteDialog extends ConsumerStatefulWidget {
  final String targetId;
  final InviteType type;

  const InviteDialog({super.key, required this.targetId, required this.type});

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  final _emailController = TextEditingController(); // Or userID controller
  // For now, assume we invite by User ID as we don't have email lookup easily without Cloud Functions or massive query.
  // Or generate Link (Phase 2 Task 4).
  // Let's implement Link Generation primarily as it's easier without user search.

  bool _isLoading = false;
  String? _generatedLink;

  @override
  Widget build(BuildContext context) {
    final myProfileAsync = ref.watch(myProfileProvider);

    return AlertDialog(
      title: const Text('Üye Davet Et'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arkadaş listenizden birini seçin veya link paylaşın.'),
            const SizedBox(height: 16),

            // Friend Selector
            myProfileAsync.when(
              data: (profile) {
                if (profile == null) return const Text('Profil yüklenemedi.');
                if (profile.friends.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Henüz arkadaşınız yok. Önce arkadaş ekleyin.'),
                  );
                }

                return FutureBuilder<List<UserProfile>>(
                  future: ref
                      .read(userServiceProvider)
                      .getProfiles(profile.friends),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Arkadaş listesi alınamadı.');
                    }

                    final friends = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Arkadaş Seç',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: friends.map((friend) {
                        return DropdownMenuItem(
                          value: friend.uid,
                          child: Text(friend.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _emailController.text = value ?? '';
                      },
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Hata: $err'),
            ),

            const SizedBox(height: 16),
            if (_generatedLink != null) ...[
              const Text('Davet Linki:'),
              SelectableText(
                _generatedLink!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton.tonal(
          onPressed: _generateLink,
          child: const Text('Link Oluştur'),
        ),
        FilledButton(
          onPressed: _sendInvite,
          // Disable if no friend selected (controller empty) and no user typed (but user typing is removed now)
          // But actually we are setting controller text on change.
          child: const Text('Davet Et'),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    final userId = _emailController.text.trim();
    if (userId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(inviteServiceProvider)
          .createInvite(
            type: widget.type,
            targetId: widget.targetId,
            inviteeId: userId,
            role: JournalRole.editor, // Default to editor? allow selection?
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Davet gönderildi')));
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

  Future<void> _generateLink() async {
    setState(() => _isLoading = true);
    try {
      final invite = await ref
          .read(inviteServiceProvider)
          .createInvite(
            type: widget.type,
            targetId: widget.targetId,
            inviteeId: null, // Public
            role: JournalRole.editor,
          );

      // Generate Deep Link (Mock for now until DeepLinkService)
      final link = 'https://journalapp.link/invite/${invite.id}';

      setState(() {
        _generatedLink = link;
      });
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
