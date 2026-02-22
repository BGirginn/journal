import 'package:flutter/material.dart';

/// Page background style options
enum PageBackgroundStyle { blank, lined, grid, dotted }

/// Journal theme definition
class JournalTheme {
  final String id;
  final String name;
  final List<Color> coverGradient;
  final Color pageBackground;
  final PageBackgroundStyle pageStyle;
  final String defaultFont;
  final double rotationVariance;
  final bool snapToGrid;
  final List<String> pageHints;
  final IconData coverIcon;

  const JournalTheme({
    required this.id,
    required this.name,
    required this.coverGradient,
    required this.pageBackground,
    this.pageStyle = PageBackgroundStyle.lined,
    this.defaultFont = 'default',
    this.rotationVariance = 0.0,
    this.snapToGrid = true,
    this.pageHints = const [],
    this.coverIcon = Icons.book,
  });

  /// Get line color based on page style
  Color get lineColor {
    switch (pageStyle) {
      case PageBackgroundStyle.lined:
        return Colors.blue.withAlpha(20);
      case PageBackgroundStyle.grid:
        return const Color(0xFFCFAF8A).withValues(alpha: 0.3);
      case PageBackgroundStyle.dotted:
        return const Color(0xFFB6926A).withValues(alpha: 0.5);
      case PageBackgroundStyle.blank:
        return Colors.transparent;
    }
  }
}

/// Built-in themes
class BuiltInThemes {
  static const defaultTheme = JournalTheme(
    id: 'default',
    name: 'Canlı Sıcak',
    coverGradient: [Color(0xFFE7B562), Color(0xFFC8742A)],
    pageBackground: Color(0xFFFFF8EE),
    pageStyle: PageBackgroundStyle.lined,
    coverIcon: Icons.book,
    pageHints: ['Bugün nasıl hissediyorsun?', 'Aklındaki en önemli şey ne?'],
  );

  static const vintage = JournalTheme(
    id: 'vintage',
    name: 'Vintage Defter',
    coverGradient: [Color(0xFF8D6E63), Color(0xFF5D4037)],
    pageBackground: Color(0xFFFFF8E1),
    pageStyle: PageBackgroundStyle.lined,
    defaultFont: 'serif',
    rotationVariance: 2.0,
    snapToGrid: false,
    coverIcon: Icons.menu_book,
    pageHints: ['Eski bir anı canlandır...', 'Dün ne öğrendin?'],
  );

  static const dark = JournalTheme(
    id: 'dark',
    name: 'Canlı Gece',
    coverGradient: [Color(0xFF4D2F1E), Color(0xFF2B1C15)],
    pageBackground: Color(0xFF2B221B),
    pageStyle: PageBackgroundStyle.dotted,
    coverIcon: Icons.nights_stay,
    pageHints: [
      'Gece sakinliğinde ne düşünüyorsun?',
      'Yarın için bir dilek...',
    ],
  );

  static const pastel = JournalTheme(
    id: 'pastel',
    name: 'Pastel Rüyalar',
    coverGradient: [Color(0xFFFFB6C1), Color(0xFF87CEEB)],
    pageBackground: Color(0xFFFFF0F5),
    pageStyle: PageBackgroundStyle.grid,
    coverIcon: Icons.favorite,
    pageHints: ['Bugün seni mutlu eden ne?', 'Minnet duyduğun 3 şey...'],
  );

  static const nature = JournalTheme(
    id: 'nature',
    name: 'Doğa Notları',
    coverGradient: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
    pageBackground: Color(0xFFF1F8E9),
    pageStyle: PageBackgroundStyle.blank,
    coverIcon: Icons.eco,
    pageHints: ['Bugün doğada ne fark ettin?', 'En sevdiğin mevsim hangisi?'],
  );

  /// Get all available themes
  static List<JournalTheme> get all => [
    defaultTheme,
    vintage,
    dark,
    pastel,
    nature,
  ];

  /// Get theme by ID
  static JournalTheme getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => defaultTheme,
    );
  }
}
