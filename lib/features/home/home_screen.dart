import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/ui/glass_card.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/theme/journal_theme.dart';
import 'package:journal_app/providers/providers.dart';
import 'package:journal_app/features/journal/journal_view_screen.dart';
import 'package:journal_app/features/notifications/notifications_screen.dart';
import 'package:journal_app/features/invite/invite_service.dart';
import 'package:journal_app/core/models/invite.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi Geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  String _getMotivationalQuote() {
    final quotes = [
      '"Bugün yazdıkların, yarının hazineleridir."',
      '"Her gün yeni bir sayfa, yeni bir başlangıç."',
      '"Düşüncelerini yazıya dök, zihnini özgür bırak."',
      '"Anılar geçicidir, yazdıkların kalıcı."',
      '"Bir günlük, kendi kendine bir mektuptur."',
    ];
    final index = DateTime.now().day % quotes.length;
    return quotes[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(myProfileProvider);
    final journalsAsync = ref.watch(journalsProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.tertiary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section - Greeting
            _buildHeroSection(context, profileAsync),
            const SizedBox(height: 24),

            // Quick Stats
            journalsAsync.when(
              data: (journals) => _buildStatsCard(context, journals.length),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Recent Journals
            journalsAsync.when(
              data: (journals) =>
                  _buildRecentJournals(context, journals.take(4).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Hata: $e'),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    AsyncValue<UserProfile?> profileAsync,
  ) {
    final greeting = _getGreeting();
    final quote = _getMotivationalQuote();
    final colorScheme = Theme.of(context).colorScheme;

    final displayName =
        profileAsync.value?.firstName ??
        profileAsync.value?.displayName ??
        'Kullanıcı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Notifications
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(delay: 100.ms),

            // Notification Bell with Badge
            // Notification Bell with Badge
            Consumer(
              builder: (context, ref, child) {
                final inviteService = ref.watch(inviteServiceProvider);
                return StreamBuilder<List<Invite>>(
                  stream: inviteService.watchMyInvites(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      );
                    }

                    final invites = snapshot.data!;
                    final pendingCount = invites
                        .where((i) => i.status == InviteStatus.pending)
                        .length;

                    return IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: Badge(
                        isLabelVisible: pendingCount > 0,
                        label: Text('$pendingCount'),
                        child: Icon(
                          pendingCount > 0
                              ? Icons.notifications_active
                              : Icons.notifications_outlined,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Greeting
        Text(
          '$greeting, $displayName 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ).animate().fadeIn(delay: 200.ms).moveX(begin: -20, end: 0),

        const SizedBox(height: 16),

        // Motivational Quote
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, int journalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İstatistikler',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: Icons.book_rounded,
                value: journalCount.toString(),
                label: 'Günlük',
                color: colorScheme.primary,
              ),
              _buildStatItem(
                context,
                icon: Icons.calendar_today_rounded,
                value: DateTime.now().day.toString(),
                label: 'Gün',
                color: colorScheme.secondary,
              ),
              _buildStatItem(
                context,
                icon: Icons.emoji_events_rounded,
                value: '${(journalCount * 3)}',
                label: 'Sayfa',
                color: colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJournals(
    BuildContext context,
    List<dynamic> recentJournals,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (recentJournals.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(
              Icons.book_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz günlük yok',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'İlk günlüğünü oluşturmak için aşağıdaki butona tıkla!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Günlükler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentJournals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final journal = recentJournals[index];
              final theme = BuiltInThemes.getById(journal.coverStyle);
              return _buildJournalCard(context, journal, theme);
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildJournalCard(
    BuildContext context,
    dynamic journal,
    dynamic theme,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JournalViewScreen(journal: journal),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.coverGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (theme.coverGradient[0] as Color).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(theme.coverIcon, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                journal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.group_rounded,
                label: 'Takımlar',
                color: colorScheme.secondary,
                onTap: () => context.push('/teams'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.sticky_note_2_rounded,
                label: 'Çıkartmalar',
                color: colorScheme.tertiary,
                onTap: () => context.push('/stickers'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}
