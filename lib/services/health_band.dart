import 'package:flutter/material.dart';

/// Presentation for a financial health score.
///
/// The dashboard card, the health-score screen and the risk-warning sheets all
/// used to pick their own colours — and mostly hardcoded green — so a customer
/// scoring 610 still saw a green shield and the word "Excellent". Thresholds
/// live here once and mirror the backend's own banding in
/// `healthscore.Calculate`: green ≥ 750, amber ≥ 550, red below.
enum HealthBand {
  green,
  amber,
  red,

  /// Score not loaded yet. Renders neutral rather than guessing green.
  unknown;

  /// Band for a 300–900 score, matching the backend's cut-offs.
  static HealthBand fromScore(int? score) {
    if (score == null || score <= 0) return HealthBand.unknown;
    if (score >= 750) return HealthBand.green;
    if (score >= 550) return HealthBand.amber;
    return HealthBand.red;
  }

  /// Band from the backend's own label, falling back to the score.
  ///
  /// The API is authoritative when it says which band a customer is in; the
  /// score is only used when the label is missing or unrecognised.
  static HealthBand fromApi(String? band, int? score) {
    switch (band?.toLowerCase().trim()) {
      case 'green':
        return HealthBand.green;
      case 'amber':
      case 'yellow':
        return HealthBand.amber;
      case 'red':
        return HealthBand.red;
    }
    return HealthBand.fromScore(score);
  }

  Color get colour {
    switch (this) {
      case HealthBand.green:
        return const Color(0xFF16A34A);
      case HealthBand.amber:
        return const Color(0xFFF59E0B);
      case HealthBand.red:
        return const Color(0xFFDC2626);
      case HealthBand.unknown:
        return const Color(0xFF64748B);
    }
  }

  /// Icon carries the same meaning as the colour, for anyone who cannot
  /// distinguish red from green — roughly one man in twelve.
  IconData get icon {
    switch (this) {
      case HealthBand.green:
        return Icons.verified_user_outlined;
      case HealthBand.amber:
        return Icons.shield_outlined;
      case HealthBand.red:
        return Icons.gpp_maybe_outlined;
      case HealthBand.unknown:
        return Icons.help_outline_rounded;
    }
  }

  /// Short label shown beside the score.
  String get label {
    switch (this) {
      case HealthBand.green:
        return 'Healthy';
      case HealthBand.amber:
        return 'Needs attention';
      case HealthBand.red:
        return 'At risk';
      case HealthBand.unknown:
        return 'Unrated';
    }
  }

  /// Compact label for tight chrome, where "Needs attention" will not fit.
  String get shortLabel {
    switch (this) {
      case HealthBand.green:
        return 'Healthy';
      case HealthBand.amber:
        return 'Watch';
      case HealthBand.red:
        return 'At risk';
      case HealthBand.unknown:
        return '—';
    }
  }
}
