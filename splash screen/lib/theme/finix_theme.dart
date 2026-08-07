import 'package:flutter/material.dart';


abstract class FinixColors {
  /// Card shadow.
  static const navy = Color(0xFF0B2545);

  /// Dark end of the card gradient.
  static const trust = Color(0xFF13315C);

  /// Card sheen, background wash, connection glow.
  static const action = Color(0xFF2E75B6);

  /// Screen surface.
  static const cloud = Color(0xFFF8FAFC);

  /// Segment B (the dark link).
  static const ink = Color(0xFF0A1628);

  /// Version label.
  static const mist = Color(0xFF94A3B8);
}

/// Geist Mono is a variable font, so weight is driven through the `wght` axis —
/// `fontWeight` alone would render a synthetic bold.
abstract class FinixText {
  static TextStyle mono({
    double size = 14,
    Color color = FinixColors.ink,
    FontWeight weight = FontWeight.w500,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Geist Mono',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );
}

/// The splash reads its surface colour from
/// `Theme.of(context).scaffoldBackgroundColor`, so whatever theme you use must
/// set it. This is the FINIX one.
ThemeData finixTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FinixColors.cloud,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FinixColors.navy,
      primary: FinixColors.navy,
      secondary: FinixColors.action,
      surface: Colors.white,
    ),
  );
  return base.copyWith(textTheme: base.textTheme.apply(fontFamily: 'Geist'));
}
