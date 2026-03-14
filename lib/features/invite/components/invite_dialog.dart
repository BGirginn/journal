import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/core/auth/user_service.dart';

class InviteDialog extends ConsumerStatefulWidget {
  final String targetId;
  final InviteType type;
  final Set<String> excludedUserIds;

  const InviteDialog({
    super.key,
    required this.targetId,
    required this.type,
    this.excludedUserIds = const <String>{},
  });

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  String? _selectedFriendUid;
  bool _isLoading = false;
  String? _generatedLink;

  @override
  Widget build(BuildContext context) {
    final myProfileAsync = ref.watch(myProfileProvider);
    final isTeamInvite = widget.type == InviteType.team;
    final title = isTeamInvite ? 'Takıma Üye Davet Et' : 'Günlüğe Üye Davet Et';
    final subtitle = isTeamInvite
        ? 'Takıma davet etmek için takımda olmayan arkadaşlarınızdan birini seçin.'
        : 'Arkadaş listenizden birini seçin veya davet linki paylaşın.';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 16),

                myProfileAsync.when(
                  data: (profile) {
                    if (profile == null) {
                      return const Text('Profil yüklenemedi.');
                    }
                    if (profile.friends.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Henüz arkadaşınız yok. Önce arkadaş ekleyin.',
                        ),
                      );
                    }

                    return FutureBuilder<List<UserProfile>>(
                      future: ref
                          .read(userServiceProvider)
                          .getProfiles(profile.friends),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Arkadaş listesi alınamadı.');
                        }

                        final friends = snapshot.data!;
                        final availableFriends = friends
                            .where(
                              (friend) =>
                                  !widget.excludedUserIds.contains(friend.uid),
                            )
                            .toList(growable: false);
                        if (availableFriends.isEmpty) {
                          return Text(
                            isTeamInvite
                                ? 'Davet edilebilecek arkadaş kalmadı.'
                                : 'Arkadaş listesi alınamadı.',
                          );
                        }

                        final selectedValue =
                            availableFriends.any(
                              (friend) => friend.uid == _selectedFriendUid,
                            )
                            ? _selectedFriendUid
                            : null;

                        return DropdownButtonFormField<String>(
                          initialValue: selectedValue,
                          decoration: const InputDecoration(
                            labelText: 'Arkadaş Seç',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: availableFriends.map((friend) {
                            final username = friend.username?.trim();
                            final trailing =
                                (username == null || username.isEmpty)
                                ? ''
                                : ' (@$username)';
                            return DropdownMenuItem(
                              value: friend.uid,
                              child: Text('${friend.displayName}$trailing'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFriendUid = value;
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),

                const SizedBox(height: 16),
                if (!isTeamInvite && _generatedLink != null) ...[
                  const Text('Davet Linki:'),
                  SelectableText(
                    _generatedLink!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        if (!isTeamInvite)
          FilledButton.tonal(
            onPressed: _isLoading ? null : _generateLink,
            child: const Text('Link Oluştur'),
          ),
        FilledButton(
          onPressed: _isLoading || _selectedFriendUid == null
              ? null
              : _sendInvite,
          child: const Text('Davet Et'),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    final userId = _selectedFriendUid;
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir arkadaş seçin.')),
        );
      }
      return;
    }

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
