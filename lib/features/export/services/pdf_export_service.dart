import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:journal_app/core/models/journal.dart';
import 'package:journal_app/core/models/page.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/core/database/daos/block_dao.dart';

class PdfExportService {
  final BlockDao blockDao;

  PdfExportService(this.blockDao);

  Future<void> exportJournal(Journal journal, List<Page> pages) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Cover Page
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  journal.title,
                  style: pw.TextStyle(font: boldFont, fontSize: 32),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Created with Journal App',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Content Pages
    for (final page in pages) {
      final blocks = await blockDao.getBlocksForPage(
        page.id,
      ); // Need to add this method to DAO if not exists
      // Blocks are normalized [0..1]. Map to A4 size.
      // A4: 595 x 842 points.

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Stack(
              children: [
                // Render blocks
                ...blocks.map((block) {
                  return _buildBlock(
                    block,
                    PdfPageFormat.a4.width,
                    PdfPageFormat.a4.height,
                    font,
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${journal.title}_export.pdf',
    );
  }

  pw.Widget _buildBlock(
    Block block,
    double pageWidth,
    double pageHeight,
    pw.Font font,
  ) {
    final left = block.x * pageWidth;
    final top = block.y * pageHeight;
    final width = block.width * pageWidth;
    final height = block.height * pageHeight;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        child: _renderBlockContent(block, font),
      ),
    );
  }

  pw.Widget _renderBlockContent(Block block, pw.Font font) {
    if (block.type == BlockType.text) {
      final payload = TextBlockPayload.fromJson(block.payload);
      return pw.Text(
        payload.content,
        style: pw.TextStyle(font: font, fontSize: payload.fontSize),
      );
    } else if (block.type == BlockType.image) {
      final payload = ImageBlockPayload.fromJson(block.payload);
      if (payload.path != null) {
        final file = File(payload.path!);
        if (file.existsSync()) {
          final image = pw.MemoryImage(file.readAsBytesSync());
          return pw.Image(image, fit: pw.BoxFit.cover);
        }
      }
      return pw.Container(color: PdfColors.grey300);
    } else if (block.type == BlockType.audio) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Center(
          child: pw.Text(
            'Audio Note',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ),
      );
    }

    return pw.Container();
  }
}
