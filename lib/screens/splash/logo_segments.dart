import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/finix_theme.dart';
import 'segment_geometry.dart';
import 'splash_assets.dart';
import 'splash_metrics.dart';
import 'splash_motion.dart';

/// The two logo segments, assembling along the storyboard's path.
///
/// The storyboard supplies the motion — how far along its link's perimeter each
/// segment's body has travelled. The vectors supply the geometry: each segment
/// is `right_chain.svg` / `left_chain.svg` clipped to the swept region, so every
/// edge, thickness, corner radius and notch is the finished mark's own, and
/// frame 7 is the vector unclipped.
///
/// Paint order is Segment B then Segment A, matching `logo.svg`. That only
/// matters at frame 7: until the segments interlock they occupy opposite ends of
/// whichever row they share and never overlap, which is why the storyboard has
/// no frame showing one crossing the other.
class LogoSegments extends StatelessWidget {
  const LogoSegments({super.key, required this.motion, required this.scale});

  final SplashAnimations motion;
  final double scale;

  /// The two tones of the mark. The dark is `FinixColors.ink`; the light is the
  /// logo's own steel and is not a design-system token.
  static const _segmentA = Color(0xFFB9C3D1);
  static const _segmentB = FinixColors.ink;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      // `03.4`'s confirmation pulse lives here, not on the card: the card is
      // identical in every storyboard frame.
      scale: motion.segmentPulse,
      child: SizedBox(
        width: SplashMetrics.logoWidth * scale,
        height: SplashMetrics.logoHeight * scale,
        child: Stack(
          // Each 43-wide art box overhangs the 64-wide logo box by 0.87 units
          // of empty space, and the entry bars reach well outside it. The card's
          // own ClipRRect is what trims them.
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: SplashMetrics.segmentBInset * scale,
              top: 0,
              child: _Segment(
                motion: motion,
                scale: scale,
                asset: SplashAssets.segmentB,
                mirrored: true,
                color: _segmentB,
              ),
            ),
            Positioned(
              left: SplashMetrics.segmentAInset * scale,
              top: 0,
              child: _Segment(
                motion: motion,
                scale: scale,
                asset: SplashAssets.segmentA,
                mirrored: false,
                color: _segmentA,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One segment: its link vector revealed through the swept region, plus the
/// plain bar for the body that has entered the card but not yet reached the
/// link's own outline.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.motion,
    required this.scale,
    required this.asset,
    required this.mirrored,
    required this.color,
  });

  final SplashAnimations motion;
  final double scale;
  final String asset;

  /// Segment B is Segment A's motion rotated 180 degrees.
  final bool mirrored;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = SegmentPath.artBoxWidth * scale;
    final height = SegmentPath.artBoxHeight * scale;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Below the link body, in the same colour, so the two read as one bar.
          Positioned.fill(
            child: CustomPaint(
              painter: _EntryBarPainter(
                motion: motion,
                mirrored: mirrored,
                scale: scale,
                color: color,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([
              motion.segmentTail,
              motion.segmentHead,
            ]),
            builder: (context, child) => ClipPath(
              clipper: _SweepClipper(
                tail: motion.segmentTail.value,
                head: motion.segmentHead.value,
                mirrored: mirrored,
                scale: scale,
              ),
              child: child,
            ),
            // Passed as `child` so the vector is built once, not once per frame.
            child: SvgPicture.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SweepClipper extends CustomClipper<Path> {
  const _SweepClipper({
    required this.tail,
    required this.head,
    required this.mirrored,
    required this.scale,
  });

  final double tail;
  final double head;
  final bool mirrored;
  final double scale;

  @override
  Path getClip(Size size) => SegmentPath.sweep(
        tail: tail,
        head: head,
        mirrored: mirrored,
        scale: scale,
      );

  @override
  bool shouldReclip(_SweepClipper oldClipper) =>
      oldClipper.tail != tail ||
      oldClipper.head != head ||
      oldClipper.mirrored != mirrored ||
      oldClipper.scale != scale;
}

class _EntryBarPainter extends CustomPainter {
  _EntryBarPainter({
    required this.motion,
    required this.mirrored,
    required this.scale,
    required this.color,
  }) : super(
          // Repaints on the animation without rebuilding any widget.
          repaint: Listenable.merge([
            motion.segmentTail,
            motion.segmentHead,
            motion.notchFill,
          ]),
        );

  final SplashAnimations motion;
  final bool mirrored;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = SegmentPath.entryBar(
      tail: motion.segmentTail.value,
      head: motion.segmentHead.value,
      notchEnd: motion.notchFill.value,
      mirrored: mirrored,
      scale: scale,
    );
    if (bar == null) return;
    canvas.drawRect(bar, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EntryBarPainter oldDelegate) =>
      oldDelegate.mirrored != mirrored ||
      oldDelegate.scale != scale ||
      oldDelegate.color != color;
}
