import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/models/invite.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:journal_app/features/editor/editor_screen.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';
import 'package:journal_app/features/invite/components/invite_dialog.dart';
import 'package:journal_app/features/journal/journal_member_service.dart';
import 'package:journal_app/core/ui/book_page_view.dart';
import 'package:journal_app/features/export/services/pdf_export_service.dart';
import 'package:journal_app/features/search/journal_search_delegate.dart';
import 'package:journal_app/features/profile/profile_settings_screen.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';

/// Journal view screen with page flip and previews
class JournalViewScreen extends ConsumerStatefulWidget {
  final Journal journal;

  const JournalViewScreen({super.key, required this.journal});

  @override
  ConsumerState<JournalViewScreen> createState() => _JournalViewScreenState();
}

class _JournalViewScreenState extends ConsumerState<JournalViewScreen> {
  late NotebookTheme _theme;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _theme = NostalgicThemes.getById(widget.journal.coverStyle);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(pagesProvider(widget.journal.id));

    return Scaffold(
      // Use app theme background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.journal.title),
        centerTitle: true,
        elevation: 0,
        // AppBar theme handled by main.dart theme data
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Ara',
            onPressed: () => showSearch(
              context: context,
              delegate: JournalSearchDelegate(ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF Dışa Aktar',
            onPressed: () => _exportPdf(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Katılımcılar',
            onPressed: _showMembersSheet,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Arkadaş Davet Et',
            onPressed: _showInviteDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Ayarlar'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Sayfa',
            onPressed: _addPage,
          ),
        ],
      ),
      body: pagesAsync.when(
        data: (pages) => _buildPageView(pages),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  Widget _buildPageView(List<model.Page> pages) {
    if (pages.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Page indicator with navigation
        _buildPageIndicator(pages.length),

        // Pages with flip animation
        Expanded(
          child: BookPageView(
            itemCount: pages.length,
            initialPage: _currentPage,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: _PageCard(
                  page: pages[index],
                  theme: _theme,
                  onTap: () => _openEditor(pages[index]),
                ),
              );
            },
          ),
        ),

        // Page number
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sayfa ${_currentPage + 1} / ${pages.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page dots
          Row(
            children: List.generate(
              pageCount.clamp(0, 7),
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (pageCount > 7)
            Text(
              ' +${pageCount - 7}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sayfa yok',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addPage,
            icon: const Icon(Icons.add),
            label: const Text('İlk Sayfayı Ekle'),
          ),
        ],
      ),
    );
  }

  void _addPage() async {
    final createPage = ref.read(createPageProvider);
    await createPage(widget.journal.id);
  }

  void _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final pdfService = PdfExportService(ref.read(blockDaoProvider));
      final pageDao = ref.read(pageDaoProvider);

      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF hazırlanıyor...')));

      final pages = await pageDao.getPagesForJournal(widget.journal.id);
      await pdfService.exportJournal(widget.journal, pages);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _openEditor(model.Page page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorScreen(journal: widget.journal, page: page),
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          InviteDialog(targetId: widget.journal.id, type: InviteType.journal),
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _JournalMembersSheet(journal: widget.journal),
    );
  }
}

class _JournalMembersSheet extends ConsumerWidget {
  final Journal journal;

  const _JournalMembersSheet({required this.journal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(journalMemberServiceProvider);
    final userService = ref.watch(userServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: StreamBuilder<List<JournalCollaborator>>(
          stream: service.watchMembers(journal.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final collaborators =
                snapshot.data ?? const <JournalCollaborator>[];
            final ownerId = journal.ownerId;
            final memberIds = <String>{
              if (ownerId != null && ownerId.isNotEmpty) ownerId,
              ...collaborators.map((m) => m.userId),
            }.toList();

            return FutureBuilder<List<UserProfile>>(
              future: userService.getProfiles(memberIds),
              builder: (context, profilesSnapshot) {
                if (profilesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profiles = profilesSnapshot.data ?? const <UserProfile>[];
                final profilesById = <String, UserProfile>{
                  for (final profile in profiles) profile.uid: profile,
                };

                final items = <_JournalMemberListItem>[];
                if (ownerId != null && ownerId.isNotEmpty) {
                  final ownerProfile = profilesById[ownerId];
                  items.add(
                    _JournalMemberListItem(
                      title: ownerProfile?.displayName ?? ownerId,
                      subtitle: ownerProfile?.username == null
                          ? null
                          : '@${ownerProfile!.username}',
                      role: JournalRole.owner,
                    ),
                  );
                }
                for (final member in collaborators) {
                  if (member.userId == ownerId) {
                    continue;
                  }
                  final profile = profilesById[member.userId];
                  items.add(
                    _JournalMemberListItem(
                      title: profile?.displayName ?? member.userId,
                      subtitle: profile?.username == null
                          ? null
                          : '@${profile!.username}',
                      role: member.role,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katılımcılar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items.length} kişi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'Henüz katılımcı yok.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, thickness: 0.6),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  item.title.isEmpty
                                      ? '?'
                                      : item.title
                                            .substring(0, 1)
                                            .toUpperCase(),
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: item.subtitle == null
                                  ? null
                                  : Text(item.subtitle!),
                              trailing: Text(
                                item.role.displayName,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _JournalMemberListItem {
  final String title;
  final String? subtitle;
  final JournalRole role;

  const _JournalMemberListItem({
    required this.title,
    required this.subtitle,
    required this.role,
  });
}

/// Page card with content preview
class _PageCard extends ConsumerWidget {
  final model.Page page;
  final NotebookTheme theme;
  final VoidCallback onTap;

  const _PageCard({
    required this.page,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blocksProvider(page.id));
    final colorScheme = Theme.of(context).colorScheme;

    // Decode ink strokes if any
    final strokes = page.inkData.isNotEmpty
        ? InkStrokeData.decodeStrokes(page.inkData)
        : <InkStrokeData>[];

    // Check if page has any visual content (blocks or ink)
    // We'll perform this check inside the async builder for blocks

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: theme.visuals.pageColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: blocksAsync.when(
            data: (blocks) {
              final sortedBlocks = List<Block>.from(blocks)
                ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
              final hasContent = blocks.isNotEmpty || strokes.isNotEmpty;

              if (!hasContent) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: _buildPageBackground()),
                    _buildTapHint(context),
                  ],
                );
              }

              // Use FittedBox to show the full page scaled down to fit the card
              // This ensures the lines and content are proportional
              const referenceSize = Size(360, 640);

              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: referenceSize.width,
                  height: referenceSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      // Background
                      Positioned.fill(child: _buildPageBackground()),

                      // Blocks
                      Stack(
                        clipBehavior: Clip.none,
                        children: sortedBlocks.map((block) {
                          return BlockWidget(
                            block: block,
                            pageSize: referenceSize,
                            isSelected: false,
                            onDoubleTap: null, // Read-only
                          );
                        }).toList(),
                      ),

                      // Ink (top layer)
                      if (strokes.isNotEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: OptimizedInkPainter(
                              strokes: strokes,
                              currentStroke: null,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Hata: $e')),
          ),
        ),
      ),
    );
  }

  // _buildContentPreview is removed/replaced by the visual preview above

  Widget _buildPageBackground() {
    if (theme.visuals.assetPath != null) {
      return Image.asset(
        theme.visuals.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CustomPaint(
          painter: NostalgicPagePainter(theme: theme),
          size: Size.infinite,
        ),
      );
    }
    return CustomPaint(
      painter: NostalgicPagePainter(theme: theme),
      size: Size.infinite,
    );
  }

  Widget _buildTapHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Düzenlemek için dokunun',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
