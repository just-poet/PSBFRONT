import 'package:flutter/material.dart';

import '../../theme/finix_theme.dart';
import 'splash_metrics.dart';

/// The flat backdrop: the app's cloud surface plus the very soft blue wash the
/// design drops in from the top edge.
///
/// Static. The emerging glow and the breathing idle from the superseded v2 spec
/// are gone — neither appears in any storyboard frame, and `03.6` forbids
/// introducing visual effects the storyboard does not contain.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  /// From `Splash screen.svg`: a radial fill centred on the top edge with
  /// rx 275.772, ry 1193.6, `#2E75B6` at 7 % fading out by 60 % of the radius.
  static const _washRadius = 275.772 / SplashMetrics.designWidth; // 0.707
  static const _washStretch = 1193.6 / 275.772; // 4.33
  static const _washFadeStop = 0.6;

  /// `FinixColors.action` at 7 % (0.07 * 255 = 18 = 0x12).
  static const _washColor = Color(0x122E75B6);
  static const _washClear = Color(0x002E75B6);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Theme-driven so the splash tracks the app surface, not a copy of it.
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: _washRadius,
          transform: _VerticalStretch(_washStretch),
          colors: [_washColor, _washClear],
          stops: [0.0, _washFadeStop],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Stretches a radial shader vertically about the top edge of the paint box,
/// turning Flutter's circular gradient into the tall ellipse the design uses.
@immutable
class _VerticalStretch extends GradientTransform {
  const _VerticalStretch(this.factor);

  final double factor;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // y' = factor * (y - bounds.top) + bounds.top
    return Matrix4.identity()
      ..setEntry(1, 1, factor)
      ..setEntry(1, 3, bounds.top * (1 - factor));
  }
}

/// Frame 7's connection glow: one blue halo that expands from behind the
/// completed mark and fades out.
///
/// `03.4`: it begins only after interlock, supports the logo and never becomes
/// the focus — so it is sized to the logo box rather than the card, and drawn as
/// a shadow behind an opaque card, which means only the part that would spill
/// past the mark is ever visible.
class ConnectionGlow extends StatelessWidget {
  const ConnectionGlow({
    super.key,
    required this.scale,
    required this.opacity,
    required this.glowScale,
  });

  final double scale;
  final Animation<double> opacity;
  final Animation<double> glowScale;

  @override
  Widget build(BuildContext context) {
    final width = SplashMetrics.logoWidth * scale;
    final height = SplashMetrics.logoHeight * scale;

    return ScaleTransition(
      scale: glowScale,
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: opacity,
          builder: (context, _) {
            final alpha = opacity.value;
            // Outside its 250 ms pass there is nothing to draw at all.
            if (alpha <= 0) return const SizedBox.shrink();
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: FinixColors.action.withValues(alpha: alpha),
                    blurRadius: _blurRadiusForFigmaBlur(
                      SplashMetrics.glowBlur * scale,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// `06` quotes an 18 px blur in the design tool's units, where the value is
  /// twice the Gaussian sigma. Flutter's `blurRadius` is a third unit again, so
  /// convert through sigma.
  static double _blurRadiusForFigmaBlur(double blur) =>
      (blur / 2 - 0.5) / 0.57735;
}
