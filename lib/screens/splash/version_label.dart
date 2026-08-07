import 'package:flutter/material.dart';

import '../../theme/finix_theme.dart';
import 'splash_metrics.dart';

/// The muted build string pinned to the bottom of the splash.
///
/// Geist Mono, 11 px, `FinixColors.mist` — read straight off the design's
/// vector text (slashed zero and all).
class VersionLabel extends StatelessWidget {
  const VersionLabel({
    super.key,
    required this.opacity,
    required this.scale,
    this.label = defaultLabel,
  });

  /// Matches the label baked into `Splash screen.svg`. In production feed this
  /// from `package_info_plus` rather than shipping a frozen string.
  static const defaultLabel = 'v 0.1.4 · build 143';

  final Animation<double> opacity;
  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: FinixText.mono(
          size: SplashMetrics.versionFontSize * scale,
          color: FinixColors.mist,
          weight: FontWeight.w400,
          letterSpacing: SplashMetrics.versionLetterSpacing * scale,
        ),
      ),
    );
  }
}
