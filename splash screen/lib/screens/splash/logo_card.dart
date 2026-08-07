import 'package:flutter/material.dart';

import '../../theme/finix_theme.dart';
import 'logo_segments.dart';
import 'splash_metrics.dart';
import 'splash_motion.dart';

/// The rounded navy card the segments assemble inside.
///
/// The storyboard draws this card identically in all seven frames, so it does
/// not materialise — it only fades up over the first 300 ms, at full scale and
/// position, and then holds. `05`'s build order says the same thing: render the
/// card, do not animate it.
///
/// Drawn natively rather than loaded from `Background+Shadow.svg` so the two
/// stacked shadows can be real `BoxShadow`s at the sigmas the design specifies.
class LogoCard extends StatelessWidget {
  const LogoCard({super.key, required this.motion, required this.scale});

  final SplashAnimations motion;
  final double scale;

  /// The card's top-left highlight. Not a global token — it exists only here, as
  /// the light end of the card's own gradient.
  static const _cardHighlight = Color(0xFF4B81C4);

  /// `#4B81C4 -> #13315C` on the top-left -> bottom-right diagonal.
  static const _fill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_cardHighlight, FinixColors.trust],
  );

  /// The blue sheen over the fill, centred 30 % / 30 % into the card
  /// (`FinixColors.action` at 50 %, gone by 60 % of the radius).
  static const _sheen = RadialGradient(
    center: Alignment(-0.4, -0.4),
    radius: 120.774 / SplashMetrics.cardHeight,
    colors: [Color(0x802E75B6), Color(0x002E75B6)],
    stops: [0.0, 0.6],
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SplashMetrics.cardRadius * scale);

    return FadeTransition(
      opacity: motion.cardOpacity,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: _shadows()),
        child: ClipRRect(
          // Also what trims the segments as they travel in from off-card.
          borderRadius: radius,
          child: SizedBox(
            width: SplashMetrics.cardWidth * scale,
            height: SplashMetrics.cardHeight * scale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(decoration: BoxDecoration(gradient: _fill)),
                const DecoratedBox(decoration: BoxDecoration(gradient: _sheen)),
                Positioned(
                  left: SplashMetrics.logoLeft * scale,
                  top: SplashMetrics.logoTop * scale,
                  child: LogoSegments(motion: motion, scale: scale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design's two stacked shadows, at full strength throughout — `03.4`
  /// wants soft shadows and no elevation changes, and the storyboard never
  /// varies them.
  ///
  /// [BoxShadow.blurRadius] is not a Gaussian sigma; Flutter converts it with
  /// `sigma = radius * 0.57735 + 0.5`. Inverting that keeps these matching the
  /// `stdDeviation` values in the export instead of coming out noticeably softer.
  List<BoxShadow> _shadows() => [
        BoxShadow(
          color: FinixColors.navy
              .withValues(alpha: SplashMetrics.shadowNearAlpha),
          offset: Offset(0, SplashMetrics.shadowNearDy * scale),
          blurRadius:
              _blurRadiusForSigma(SplashMetrics.shadowNearSigma) * scale,
        ),
        BoxShadow(
          color:
              FinixColors.navy.withValues(alpha: SplashMetrics.shadowFarAlpha),
          offset: Offset(0, SplashMetrics.shadowFarDy * scale),
          blurRadius: _blurRadiusForSigma(SplashMetrics.shadowFarSigma) * scale,
        ),
      ];

  static double _blurRadiusForSigma(double sigma) => (sigma - 0.5) / 0.57735;
}
