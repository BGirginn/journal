import 'package:flutter/material.dart';

class JournalRadiusScale extends ThemeExtension<JournalRadiusScale> {
  final double small;
  final double medium;
  final double large;
  final double modal;

  const JournalRadiusScale({
    required this.small,
    required this.medium,
    required this.large,
    required this.modal,
  });

  static const standard = JournalRadiusScale(
    small: 8,
    medium: 16,
    large: 24,
    modal: 32,
  );

  @override
  JournalRadiusScale copyWith({
    double? small,
    double? medium,
    double? large,
    double? modal,
  }) {
    return JournalRadiusScale(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      modal: modal ?? this.modal,
    );
  }

  @override
  ThemeExtension<JournalRadiusScale> lerp(
    covariant ThemeExtension<JournalRadiusScale>? other,
    double t,
  ) {
    if (other is! JournalRadiusScale) {
      return this;
    }
    return JournalRadiusScale(
      small: _lerp(small, other.small, t),
      medium: _lerp(medium, other.medium, t),
      large: _lerp(large, other.large, t),
      modal: _lerp(modal, other.modal, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
