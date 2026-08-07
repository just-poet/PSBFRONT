import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'splash_assets.dart';
import 'splash_metrics.dart';
import 'splash_motion.dart';

/// Frame 7: "finix" fades up 6 px, once the mark is complete.
///
/// `03.4` treats the wordmark as a single object — no letter spacing, no
/// per-character motion, no bounce. The 4 px focus-pull blur from the superseded
/// v2 spec is gone; no storyboard document asks for it.
class FinixWordmark extends StatelessWidget {
  const FinixWordmark({super.key, required this.motion, required this.scale});

  final SplashAnimations motion;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: motion.wordmarkSlide,
      child: FadeTransition(
        opacity: motion.wordmarkOpacity,
        child: SvgPicture.asset(
          SplashAssets.wordmark,
          width: SplashMetrics.wordmarkWidth * scale,
          height: SplashMetrics.wordmarkHeight * scale,
          fit: BoxFit.fill,
          semanticsLabel: 'Finix',
        ),
      ),
    );
  }
}
