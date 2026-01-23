// import 'dart:io';
// import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/providers/journal_providers.dart';
import 'package:journal_app/features/editor/editor_screen.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';
import 'package:journal_app/core/ui/book_page_view.dart';
import 'package:journal_app/features/export/services/pdf_export_service.dart';
import 'package:journal_app/features/search/journal_search_delegate.dart';
import 'package:journal_app/features/settings/settings_screen.dart';
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
    // final isDark = _theme.id == 'midnight';

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
              color: Colors.black.withValues(
                alpha: 0.2,
              ), // Updated for Flutter 3
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: blocksAsync.when(
            data: (blocks) {
              final hasContent = blocks.isNotEmpty || strokes.isNotEmpty;

              if (!hasContent) {
                return Stack(
                  children: [
                    CustomPaint(
                      painter: NostalgicPagePainter(theme: theme),
                      size: Size.infinite,
                    ),
                    _buildTapHint(),
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
                      CustomPaint(
                        painter: NostalgicPagePainter(theme: theme),
                        size: Size.infinite,
                      ),

                      // Ink
                      if (strokes.isNotEmpty)
                        CustomPaint(
                          painter: OptimizedInkPainter(
                            strokes: strokes,
                            currentStroke: null,
                          ),
                          size: Size.infinite,
                        ),

                      // Blocks
                      Stack(
                        clipBehavior: Clip.none,
                        children: blocks.map((block) {
                          return BlockWidget(
                            block: block,
                            pageSize: referenceSize,
                            isSelected: false,
                            onDoubleTap: null, // Read-only
                          );
                        }).toList(),
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
