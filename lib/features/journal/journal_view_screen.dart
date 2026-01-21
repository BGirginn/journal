import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:journal_app/features/editor/editor_screen.dart';
import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';
import 'package:journal_app/core/ui/book_page_view.dart';
import 'package:journal_app/features/export/services/pdf_export_service.dart';
import 'package:journal_app/features/search/journal_search_delegate.dart';
import 'package:journal_app/features/settings/settings_screen.dart';

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
    final isDark = _theme.id == 'midnight';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF0EDE8),
      appBar: AppBar(
        title: Text(widget.journal.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
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
              color: _theme.id == 'midnight'
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    final isDark = _theme.id == 'midnight';

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
                      ? Colors.deepPurple
                      : (isDark ? Colors.grey[600] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (pageCount > 7)
            Text(
              ' +${pageCount - 7}',
              style: TextStyle(color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sayfa yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: theme.visuals.pageColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Page background
              CustomPaint(
                painter: NostalgicPagePainter(theme: theme),
                size: Size.infinite,
              ),

              // Content preview
              blocksAsync.when(
                data: (blocks) => _buildContentPreview(blocks),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),

              // Tap hint overlay
              blocksAsync.when(
                data: (blocks) =>
                    blocks.isEmpty ? _buildTapHint() : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(List<Block> blocks) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final textColor = theme.visuals.textColor.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.take(3).map((block) {
          if (block.type == BlockType.text) {
            final payload = TextBlockPayload.fromJson(block.payload);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                payload.content.length > 50
                    ? '${payload.content.substring(0, 50)}...'
                    : payload.content,
                style: TextStyle(fontSize: 12, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          } else if (block.type == BlockType.image) {
            final payload = ImageBlockPayload.fromJson(block.payload);
            if (payload.path != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ImageFrameWidget(
                  path: payload.path!,
                  frameStyle: payload.frameStyle,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.image, size: 20, color: Colors.grey),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  Widget _buildTapHint() {
    final isDark = theme.id == 'midnight';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Düzenlemek için dokunun',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider for blocks of a page
final blocksProvider = StreamProvider.family<List<Block>, String>((
  ref,
  pageId,
) {
  final dao = ref.watch(blockDaoProvider);
  return dao.watchBlocksForPage(pageId);
});
