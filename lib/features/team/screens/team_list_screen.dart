import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:journal_app/core/models/team.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamService = ref.watch(teamServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Takımlarım')),
      body: StreamBuilder<List<Team>>(
        stream: teamService.watchMyTeams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bir takımınız yok',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Oluşturmak için + butonuna basın'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: teams.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: team.avatarUrl != null
                        ? NetworkImage(team.avatarUrl!)
                        : null,
                    child: team.avatarUrl == null
                        ? Text(team.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(team.name),
                  subtitle: Text(team.description ?? 'Açıklama yok'),
                  onTap: () {
                    // Navigate to Team Management
                    context.push('/teams/${team.id}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateTeamDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Takım Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Takım Adı',
                hintText: 'Örn: Ailem, İş Arkadaşları',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe bağlı)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              try {
                await ref
                    .read(teamServiceProvider)
                    .createTeam(
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Takım oluşturuldu')));
    }
  }
}
