import 'package:flutter/material.dart';

/// Nostalgic notebook themes with unique visual identities
class NotebookTheme {
  final String id;
  final String name;
  final String description;
  final NotebookVisuals visuals;
  final NotebookTexture texture;

  const NotebookTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.visuals,
    required this.texture,
  });
}

/// Visual properties of notebook
class NotebookVisuals {
  final List<Color> coverGradient;
  final Color pageColor;
  final Color? lineColor;
  final Color? marginColor;
  final Color textColor;
  final double lineSpacing;
  final double marginLeft;
  final bool hasMarginLine;
  final bool hasHoles;
  final BorderRadius cornerRadius;
  final List<BoxShadow> shadows;

  const NotebookVisuals({
    required this.coverGradient,
    required this.pageColor,
    this.lineColor,
    this.marginColor,
    required this.textColor,
    this.lineSpacing = 28,
    this.marginLeft = 40,
    this.hasMarginLine = false,
    this.hasHoles = false,
    this.cornerRadius = const BorderRadius.all(Radius.circular(4)),
    this.shadows = const [],
  });
}

/// Texture type for notebook pages
enum NotebookTexture {
  smooth, // Clean paper
  aged, // Yellowed, vintage
  craft, // Brown kraft paper
  watercolor, // Textured for art
  grid, // Graph paper
  dotted, // Bullet journal dots
  blank, // No lines
}

/// Premium nostalgic themes
class NostalgicThemes {
  // 90s School Notebook - Spiral bound, wide ruled
  static const school90s = NotebookTheme(
    id: 'school_90s',
    name: '90\'lar Okul Defteri',
    description: 'Spiral ciltli, geniş çizgili nostaljik defter',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
      pageColor: Color(0xFFFFFBF0),
      lineColor: Color(0xFFB3E5FC),
      marginColor: Color(0xFFFFCDD2),
      textColor: Color(0xFF1A237E),
      lineSpacing: 32,
      marginLeft: 50,
      hasMarginLine: true,
      hasHoles: true,
    ),
    texture: NotebookTexture.smooth,
  );

  // Grandfather's Leather Journal
  static const leatherJournal = NotebookTheme(
    id: 'leather_journal',
    name: 'Deri Günlük',
    description: 'Eskitilmiş deri kaplı, krem renkli sayfalar',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF5D4037), Color(0xFF3E2723)],
      pageColor: Color(0xFFFFF8E1),
      lineColor: Color(0xFFD7CCC8),
      textColor: Color(0xFF4E342E),
      lineSpacing: 30,
      hasMarginLine: false,
      cornerRadius: BorderRadius.all(Radius.circular(2)),
      shadows: [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    texture: NotebookTexture.aged,
  );

  // Artist's Sketchbook
  static const sketchbook = NotebookTheme(
    id: 'sketchbook',
    name: 'Eskiz Defteri',
    description: 'Kalın dokulu kağıt, çizim için ideal',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF37474F), Color(0xFF263238)],
      pageColor: Color(0xFFFAFAFA),
      textColor: Color(0xFF212121),
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.watercolor,
  );

  // Bullet Journal - Minimalist dotted
  static const bulletJournal = NotebookTheme(
    id: 'bullet',
    name: 'Bullet Journal',
    description: 'Minimal noktalı sayfa, organize düşünceler',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF455A64), Color(0xFF37474F)],
      pageColor: Color(0xFFFFFDE7),
      lineColor: Color(0xFFE0E0E0),
      textColor: Color(0xFF424242),
      lineSpacing: 20,
    ),
    texture: NotebookTexture.dotted,
  );

  // Romantic Diary - Pink, floral vibes
  static const romanticDiary = NotebookTheme(
    id: 'romantic',
    name: 'Romantik Günlük',
    description: 'Pembe ve çiçekli, duygusal anlar için',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFEC407A), Color(0xFFAD1457)],
      pageColor: Color(0xFFFCE4EC),
      lineColor: Color(0xFFF8BBD9),
      textColor: Color(0xFF880E4F),
      lineSpacing: 26,
      cornerRadius: BorderRadius.all(Radius.circular(12)),
    ),
    texture: NotebookTexture.smooth,
  );

  // Midnight Writer - Dark theme
  static const midnightWriter = NotebookTheme(
    id: 'midnight',
    name: 'Gece Yazarı',
    description: 'Koyu tema, gece ilhamları için',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      pageColor: Color(0xFF1E1E2E),
      lineColor: Color(0xFF2D2D44),
      textColor: Color(0xFFE0E0E0),
      lineSpacing: 28,
    ),
    texture: NotebookTexture.smooth,
  );

  // Kraft Paper - Eco, natural
  static const kraftPaper = NotebookTheme(
    id: 'kraft',
    name: 'Kraft Kağıt',
    description: 'Doğal kahverengi, eko-dostane',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
      pageColor: Color(0xFFD7CCC8),
      lineColor: Color(0xFFBCAAA4),
      textColor: Color(0xFF4E342E),
      lineSpacing: 30,
    ),
    texture: NotebookTexture.craft,
  );

  // Graph Paper - Engineering
  static const graphPaper = NotebookTheme(
    id: 'graph',
    name: 'Kareli Defter',
    description: 'Mühendislik ve matematik için',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFF00695C), Color(0xFF004D40)],
      pageColor: Color(0xFFF5F5F5),
      lineColor: Color(0xFFB2DFDB),
      textColor: Color(0xFF00695C),
      lineSpacing: 20,
    ),
    texture: NotebookTexture.grid,
  );

  static List<NotebookTheme> get all => [
    school90s,
    leatherJournal,
    sketchbook,
    bulletJournal,
    romanticDiary,
    midnightWriter,
    kraftPaper,
    graphPaper,
  ];

  static NotebookTheme getById(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => school90s);
  }
}
