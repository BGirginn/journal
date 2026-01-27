import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:journal_app/core/models/team.dart';
import 'package:journal_app/core/models/team_member.dart';

import 'package:journal_app/features/invite/components/invite_dialog.dart';
import 'package:journal_app/core/models/invite.dart';

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

    // We need to fetch the team details first.
    // Since we don't have a single team stream exposed yet, let's just use watchMyTeams and find it,
    // or better, implement getTeamById in service or use FutureBuilder if it's not reactive for properties.
    // Ideally, we should have a `watchTeam(id)` method. But for now, let's find it in the list.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Edit Team Settings
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

          final team = snapshot.data!.cast<Team?>().firstWhere(
            (t) => t?.id == widget.teamId,
            orElse: () => null,
          );

          if (team == null) {
            return const Center(child: Text('Takım bulunamadı veya silinmiş.'));
          }

          return Column(
            children: [
              _buildTeamHeader(context, team),
              const Divider(),
              Expanded(child: _buildMemberList(context, teamService)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                InviteDialog(targetId: widget.teamId, type: InviteType.team),
          );
        },
        label: const Text('Üye Davet Et'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context, Team team) {
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
          Text(team.name, style: Theme.of(context).textTheme.headlineMedium),
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
                  final member = members[index];
                  // Note: User details (name, photo) should be fetched for this member.userId
                  // For now, show userId.

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member.userId), // Placeholder for name
                    subtitle: Text(member.role.displayName),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Çıkar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        // Handle removal
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
