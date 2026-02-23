import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/models/team.dart';
import 'package:journal_app/core/models/team_member.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/core/theme/tokens/brand_radius.dart';
import 'package:journal_app/core/ui/custom_bottom_navigation.dart';
import 'package:journal_app/features/team/team_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({super.key});

  @override
  ConsumerState<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  void _onRootNavTap(int index) {
    context.go('/?tab=$index');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final teamService = ref.watch(teamServiceProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          StreamBuilder<List<Team>>(
            stream: teamService.watchMyTeams(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              final teams = snapshot.data ?? [];
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                    decoration: BoxDecoration(
                      color: semantic.elevated,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(radius.modal),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CircleIconButton(
                                icon: LucideIcons.arrowLeft,
                                onTap: () => context.go('/?tab=2'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Takımlar',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => context.push('/notifications'),
                                icon: const Icon(LucideIcons.inbox),
                                tooltip: 'Inbox',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Arkadaşlarınla birlikte anılar oluştur',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            if (teams.isEmpty)
                              _TeamsEmptyState(
                                onCreatePressed: () =>
                                    _showCreateTeamDialog(context, ref),
                              )
                            else
                              ...teams.map(
                                (team) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TeamCard(
                                    team: team,
                                    onTap: () =>
                                        context.push('/teams/${team.id}'),
                                    memberCountBuilder:
                                        StreamBuilder<List<TeamMember>>(
                                          stream: teamService.watchMembers(
                                            team.id,
                                          ),
                                          builder: (context, memberSnapshot) {
                                            final count =
                                                memberSnapshot.data?.length ??
                                                0;
                                            return Text(
                                              '$count üye',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            );
                                          },
                                        ),
                                  ),
                                ),
                              ),
                            if (teams.isNotEmpty) const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _showCreateTeamDialog(context, ref),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    radius.large,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.plus,
                                      size: 20,
                                      color: colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Yeni Takım Oluştur',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 3,
        onItemSelected: _onRootNavTap,
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

class _TeamCard extends StatelessWidget {
  final Team team;
  final Widget memberCountBuilder;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.memberCountBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary.withValues(alpha: 0.24);
    final secondaryColor = colorScheme.secondary.withValues(alpha: 0.24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.large),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: semantic.card,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius.medium),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  border: Border.all(
                    color: semantic.divider.withValues(alpha: 0.8),
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.users,
                    color: colorScheme.onSurface,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        memberCountBuilder,
                      ],
                    ),
                  ],
                ),
              ),
              _CircleIconButton(icon: LucideIcons.chevronRight, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamsEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _TeamsEmptyState({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<JournalSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? JournalSemanticColors.dark
            : JournalSemanticColors.light);
    final radius =
        Theme.of(context).extension<JournalRadiusScale>() ??
        JournalRadiusScale.standard;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: semantic.card,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: semantic.divider.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.users, size: 40, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Henüz bir takımın yok',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Anılarını paylaşmak için yeni bir takım oluştur.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Takım Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
