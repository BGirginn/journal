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
  bool _isPageZoomed = false;

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
            dragEnabled: !_isPageZoomed,
            onPageChanged: (index) => setState(() {
              _currentPage = index;
              _isPageZoomed = false;
            }),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: _PageCard(
                  key: ValueKey(pages[index].id),
                  page: pages[index],
                  theme: _theme,
                  onTap: () => _openEditor(pages[index]),
                  onZoomChanged: (zoomed) {
                    if (index != _currentPage || _isPageZoomed == zoomed) {
                      return;
                    }
                    setState(() => _isPageZoomed = zoomed);
                  },
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
class _PageCard extends ConsumerStatefulWidget {
  final model.Page page;
  final NotebookTheme theme;
  final VoidCallback onTap;
  final ValueChanged<bool>? onZoomChanged;

  const _PageCard({
    super.key,
    required this.page,
    required this.theme,
    required this.onTap,
    this.onZoomChanged,
  });

  @override
  ConsumerState<_PageCard> createState() => _PageCardState();
}

class _PageCardState extends ConsumerState<_PageCard> {
  static const Size _referenceSize = Size(360, 640);
  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;

  @override
  void didUpdateWidget(covariant _PageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _resetZoom();
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _notifyZoomState() {
    final isZoomedNow = _zoomController.value.getMaxScaleOnAxis() > 1.01;
    if (_isZoomed == isZoomedNow) {
      return;
    }
    _isZoomed = isZoomedNow;
    widget.onZoomChanged?.call(isZoomedNow);
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    if (_isZoomed) {
      _isZoomed = false;
      widget.onZoomChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(blocksProvider(widget.page.id));
    final colorScheme = Theme.of(context).colorScheme;
    final strokes = widget.page.inkData.isNotEmpty
        ? InkStrokeData.decodeStrokes(widget.page.inkData)
        : <InkStrokeData>[];

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _resetZoom,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: widget.theme.visuals.pageColor,
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
              return InteractiveViewer(
                transformationController: _zoomController,
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                boundaryMargin: const EdgeInsets.all(120),
                clipBehavior: Clip.none,
                onInteractionStart: (_) => _notifyZoomState(),
                onInteractionUpdate: (_) => _notifyZoomState(),
                onInteractionEnd: (_) => _notifyZoomState(),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _referenceSize.width,
                    height: _referenceSize.height,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: _buildPageBackground()),
                        if (hasContent) ...[
                          Stack(
                            clipBehavior: Clip.none,
                            children: sortedBlocks
                                .map(
                                  (block) => BlockWidget(
                                    block: block,
                                    pageSize: _referenceSize,
                                    isSelected: false,
                                    onDoubleTap: null,
                                  ),
                                )
                                .toList(),
                          ),
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
                        ] else
                          _buildTapHint(context),
                      ],
                    ),
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
    if (widget.theme.visuals.assetPath != null) {
      return Image.asset(
        widget.theme.visuals.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CustomPaint(
          painter: NostalgicPagePainter(theme: widget.theme),
          size: Size.infinite,
        ),
      );
    }
    return CustomPaint(
      painter: NostalgicPagePainter(theme: widget.theme),
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
