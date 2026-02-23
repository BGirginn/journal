import 'package:flutter/material.dart';

class JournalElevationScale extends ThemeExtension<JournalElevationScale> {
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> toolShadow;

  const JournalElevationScale({
    required this.cardShadow,
    required this.toolShadow,
  });

  static const light = JournalElevationScale(
    cardShadow: [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 30,
        offset: Offset(0, 8),
      ),
    ],
    toolShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 40,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const dark = JournalElevationScale(
    cardShadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 28,
        offset: Offset(0, 8),
      ),
    ],
    toolShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        blurRadius: 42,
        offset: Offset(0, 12),
      ),
    ],
  );

  @override
  JournalElevationScale copyWith({
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? toolShadow,
  }) {
    return JournalElevationScale(
      cardShadow: cardShadow ?? this.cardShadow,
      toolShadow: toolShadow ?? this.toolShadow,
    );
  }

  @override
  ThemeExtension<JournalElevationScale> lerp(
    covariant ThemeExtension<JournalElevationScale>? other,
    double t,
  ) {
    if (other is! JournalElevationScale) {
      return this;
    }
    return JournalElevationScale(
      cardShadow: _lerpShadowList(cardShadow, other.cardShadow, t),
      toolShadow: _lerpShadowList(toolShadow, other.toolShadow, t),
    );
  }

  static List<BoxShadow> _lerpShadowList(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final maxLen = a.length > b.length ? a.length : b.length;
    final result = <BoxShadow>[];
    for (var i = 0; i < maxLen; i++) {
      final left = i < a.length ? a[i] : a.last;
      final right = i < b.length ? b[i] : b.last;
      final lerped = BoxShadow.lerp(left, right, t);
      if (lerped != null) {
        result.add(lerped);
      }
    }
    return result;
  }
}
