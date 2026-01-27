import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/models/team.dart';
import 'package:journal_app/features/invite/invite_service.dart';

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
    return AlertDialog(
      title: const Text('Üye Davet Et'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Kullanıcı ID\'si ile davet et veya link paylaş.'),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı ID',
              border: OutlineInputBorder(),
            ),
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
          if (_isLoading) const CircularProgressIndicator(),
        ],
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
        FilledButton(onPressed: _sendInvite, child: const Text('Davet Et')),
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
