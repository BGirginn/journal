import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:journal_app/core/models/team.dart';
import 'package:journal_app/core/models/team_member.dart';

import 'package:journal_app/features/invite/components/invite_dialog.dart';
import 'package:journal_app/core/models/invite.dart';

import 'package:journal_app/core/auth/user_service.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  final String teamId;

  const TeamManagementScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamManagementScreen> createState() =>
      _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final teamService = ref.watch(teamServiceProvider);
    final currentUid = ref.watch(authStateProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Yönetimi'),
        actions: [
          StreamBuilder<List<Team>>(
            stream: teamService.watchMyTeams(),
            builder: (context, snapshot) {
              final team = _findCurrentTeam(snapshot.data);
              final isOwner = team != null && team.ownerId == currentUid;
              if (!isOwner) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmAndDeleteTeam();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Takımı Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Team>>(
        stream: teamService.watchMyTeams(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = _findCurrentTeam(snapshot.data);

          if (team == null) {
            return const Center(child: Text('Takım bulunamadı veya silinmiş.'));
          }

          final isOwner = currentUid != null && team.ownerId == currentUid;

          return Column(
            children: [
              _buildTeamHeader(context, team, ref),
              const Divider(),
              Expanded(child: _buildMemberList(context, teamService)),
              if (isOwner) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showCreateTeamJournalDialog(team),
                      icon: const Icon(Icons.book_outlined),
                      label: const Text('Ortak Journal Oluştur'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmAndDeleteTeam,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Takımı Sil',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Team>>(
        stream: teamService.watchMyTeams(),
        builder: (context, snapshot) {
          final team = _findCurrentTeam(snapshot.data);
          final isOwner = team != null && team.ownerId == currentUid;
          if (!isOwner) {
            return const SizedBox.shrink();
          }

          return StreamBuilder<List<TeamMember>>(
            stream: teamService.watchMembers(widget.teamId),
            builder: (context, membersSnapshot) {
              final memberIds =
                  membersSnapshot.data
                      ?.map((member) => member.userId)
                      .toSet() ??
                  const <String>{};
              return FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteDialog(
                      targetId: widget.teamId,
                      type: InviteType.team,
                      excludedUserIds: memberIds,
                    ),
                  );
                },
                label: const Text('Üye Davet Et'),
                icon: const Icon(Icons.person_add),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Takımı Sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Takımı ve takım üyeliklerini silmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(teamServiceProvider).deleteTeam(widget.teamId);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
      context.go('/teams');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Takım silindi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Takım silinemedi: $e')));
    }
  }

  Future<void> _showCreateTeamJournalDialog(Team team) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ortak Journal Oluştur'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Journal adı girin...',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (title == null || !mounted) return;

    try {
      final teamService = ref.read(teamServiceProvider);
      final journal = await teamService.createTeamJournal(
        teamId: team.id,
        title: title,
      );
      if (mounted) {
        context.push('/journal/${journal.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Journal oluşturulamadı: $e')),
        );
      }
    }
  }

  Widget _buildTeamHeader(BuildContext context, Team team, WidgetRef ref) {
    return FutureBuilder<UserProfile?>(
      future: ref.read(userServiceProvider).getUserProfile(team.ownerId),
      builder: (context, snapshot) {
        final ownerName = snapshot.data?.displayName ?? 'Bilinmeyen Sahip';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: team.avatarUrl != null
                    ? NetworkImage(team.avatarUrl!)
                    : null,
                child: team.avatarUrl == null
                    ? Text(
                        team.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                team.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Sahip: $ownerName',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              if (team.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  team.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberList(BuildContext context, TeamService teamService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'ÜYELER',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TeamMember>>(
            stream: teamService.watchMembers(widget.teamId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data ?? [];

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return _MemberTile(member: members[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Team? _findCurrentTeam(List<Team>? teams) {
    if (teams == null) {
      return null;
    }
    return teams.cast<Team?>().firstWhere(
      (team) => team?.id == widget.teamId,
      orElse: () => null,
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final TeamMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userService = ref.watch(userServiceProvider);

    return FutureBuilder<UserProfile?>(
      future: userService.getUserProfile(member.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.displayName ?? member.userId;
        final username = user?.username?.trim();
        final handle = (username == null || username.isEmpty)
            ? ''
            : '@$username';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(name),
          subtitle: Text('${member.role.displayName} $handle'),
        );
      },
    );
  }
}
