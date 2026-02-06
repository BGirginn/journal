import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart' as model;
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/theme/nostalgic_themes.dart';
import 'package:journal_app/core/theme/nostalgic_page_painter.dart';
import 'package:journal_app/providers/database_providers.dart';
import 'package:journal_app/features/editor/drawing/ink_storage.dart';
import 'package:journal_app/features/editor/blocks/block_widget.dart';

/// Read-only preview of a journal page
class PagePreviewScreen extends ConsumerStatefulWidget {
  final Journal journal;
  final model.Page page;

  const PagePreviewScreen({
    super.key,
    required this.journal,
    required this.page,
  });

  @override
  ConsumerState<PagePreviewScreen> createState() => _PagePreviewScreenState();
}

class _PagePreviewScreenState extends ConsumerState<PagePreviewScreen> {
  late NotebookTheme _theme;
  List<Block> _blocks = [];
  List<InkStrokeData> _strokes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _theme = NostalgicThemes.getById(widget.journal.coverStyle);
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Load blocks
    final blockDao = ref.read(blockDaoProvider);
    final blocks = await blockDao.getBlocksForPage(
      widget.page.id,
    ); // One-time load

    if (mounted) {
      setState(() {
        _blocks = blocks;
      });
    }

    // Load ink strokes from page
    final pageDao = ref.read(pageDaoProvider);
    final page = await pageDao.getPageById(widget.page.id);
    if (page != null && page.inkData.isNotEmpty) {
      if (mounted) {
        setState(() {
          _strokes = InkStrokeData.decodeStrokes(page.inkData);
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Sayfa ${widget.page.pageIndex + 1}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _theme.visuals.pageColor,
                    borderRadius: _theme.visuals.cornerRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: _theme.visuals.cornerRadius,
                    child: Stack(
                      children: [
                        // Page background
                        CustomPaint(
                          painter: NostalgicPagePainter(theme: _theme),
                          size: Size.infinite,
                        ),

                        // Ink strokes
                        CustomPaint(
                          painter: OptimizedInkPainter(
                            strokes: _strokes,
                            currentStroke: null,
                          ),
                          size: Size.infinite,
                        ),

                        // Blocks
                        ..._blocks.map((block) => _buildBlock(block, pageSize)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBlock(Block block, Size pageSize) {
    return BlockWidget(block: block, pageSize: pageSize, isSelected: false);
  }
}
