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
  final String? assetPath; // New property for image backgrounds

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
    this.assetPath,
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
  static const defaultTheme = NotebookTheme(
    id: 'default',
    name: 'Gün Işığı',
    description: 'Parlak ve okunaklı varsayılan tema',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFEEC87A), Color(0xFFCC7C39)],
      pageColor: Color(0xFFFFF8ED),
      textColor: Color(0xFF2D1E11),
      lineColor: Color(0xFFDDBB93),
      marginColor: Color(0xFFE28C73),
      hasMarginLine: true,
      lineSpacing: 28,
      marginLeft: 42,
      cornerRadius: BorderRadius.all(Radius.circular(6)),
    ),
    texture: NotebookTexture.aged,
  );

  // --- Image Based Themes ---
  static const paperImage1 = NotebookTheme(
    id: 'paper_img_1',
    name: 'Özel Kağıt 1',
    description: 'Resimli Arkaplan 1',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_1.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth, // Base structure, we'll draw image over it
  );

  static const paperImage2 = NotebookTheme(
    id: 'paper_img_2',
    name: 'Özel Kağıt 2',
    description: 'Resimli Arkaplan 2',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_1.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage3 = NotebookTheme(
    id: 'paper_img_3',
    name: 'Özel Kağıt 3',
    description: 'Resimli Arkaplan 3',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_3.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage4 = NotebookTheme(
    id: 'paper_img_4',
    name: 'Özel Kağıt 4',
    description: 'Resimli Arkaplan 4',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_3.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage5 = NotebookTheme(
    id: 'paper_img_5',
    name: 'Özel Kağıt 5',
    description: 'Resimli Arkaplan 5',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_5.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage6 = NotebookTheme(
    id: 'paper_img_6',
    name: 'Özel Kağıt 6',
    description: 'Resimli Arkaplan 6',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_5.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage7 = NotebookTheme(
    id: 'paper_img_7',
    name: 'Özel Kağıt 7',
    description: 'Resimli Arkaplan 7',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_10.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage8 = NotebookTheme(
    id: 'paper_img_8',
    name: 'Özel Kağıt 8',
    description: 'Resimli Arkaplan 8',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_11.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage9 = NotebookTheme(
    id: 'paper_img_9',
    name: 'Özel Kağıt 9',
    description: 'Resimli Arkaplan 9',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_12.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage10 = NotebookTheme(
    id: 'paper_img_10',
    name: 'Özel Kağıt 10',
    description: 'Resimli Arkaplan 10',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_10.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage11 = NotebookTheme(
    id: 'paper_img_11',
    name: 'Özel Kağıt 11',
    description: 'Resimli Arkaplan 11',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_11.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage12 = NotebookTheme(
    id: 'paper_img_12',
    name: 'Özel Kağıt 12',
    description: 'Resimli Arkaplan 12',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_12.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage13 = NotebookTheme(
    id: 'paper_img_13',
    name: 'Özel Kağıt 13',
    description: 'Resimli Arkaplan 13',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_12.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage14 = NotebookTheme(
    id: 'paper_img_14',
    name: 'Özel Kağıt 14',
    description: 'Resimli Arkaplan 14',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_17.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage15 = NotebookTheme(
    id: 'paper_img_15',
    name: 'Özel Kağıt 15',
    description: 'Resimli Arkaplan 15',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_15.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage16 = NotebookTheme(
    id: 'paper_img_16',
    name: 'Özel Kağıt 16',
    description: 'Resimli Arkaplan 16',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_15.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static const paperImage17 = NotebookTheme(
    id: 'paper_img_17',
    name: 'Özel Kağıt 17',
    description: 'Resimli Arkaplan 17',
    visuals: NotebookVisuals(
      coverGradient: [Color(0xFFE3AA4F), Color(0xFFB76C30)],
      pageColor: Colors.transparent,
      textColor: Color(0xFF212121),
      assetPath: 'assets/images/papers/paper_bg_17.png',
      cornerRadius: BorderRadius.all(Radius.circular(0)),
    ),
    texture: NotebookTexture.smooth,
  );

  static List<NotebookTheme> get all => [
    defaultTheme,
    paperImage1,
    paperImage2,
    paperImage3,
    paperImage4,
    paperImage5,
    paperImage6,
    paperImage7,
    paperImage8,
    paperImage9,
    paperImage10,
    paperImage11,
    paperImage12,
    paperImage13,
    paperImage14,
    paperImage15,
    paperImage16,
    paperImage17,
  ];

  static NotebookTheme getById(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => defaultTheme);
  }
}
