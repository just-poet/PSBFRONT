import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/fade_page_route.dart';
import 'splash/background_glow.dart';
import 'splash/finix_wordmark.dart';
import 'splash/logo_card.dart';
import 'splash/splash_metrics.dart';
import 'splash/splash_motion.dart';
import 'splash/version_label.dart';

/// FINIX splash screen: the approved storyboard, ending in a cross-fade to the
/// app at 3 000 ms.
///
/// One [AnimationController] drives every frame of it, as `04` and `06` require.
/// Nothing here uses a [Timer] or a second controller, so the whole screen stays
/// in step even if a frame is late, and there is exactly one thing to dispose.
///
/// Where each piece comes from:
///   * `segment_geometry.dart` — segment shape, from the chain vectors
///   * `splash_motion.dart`    — the frame-by-frame schedule, from the storyboard
///   * `splash_metrics.dart`   — composition, from `Splash screen.svg`
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.onFinished,
  });

  /// The screen the splash hands off to once the timeline completes.
  ///
  ///     SplashScreen(nextScreen: (_) => const HomeDashboardScreen())
  final WidgetBuilder nextScreen;

  /// Replaces the default hand-off entirely — useful when the app needs to
  /// decide the destination itself (onboarding vs. dashboard), or in tests.
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final SplashAnimations _motion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: SplashPhases.total,
      vsync: this,
    )..addStatusListener(_handleStatus);
    _motion = SplashAnimations(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _motion.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// `03.4` / `06`: navigate only once the animation is complete — never during
  /// the pulse, the glow or the wordmark.
  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    Navigator.of(context).pushReplacement(
      FadePageRoute<void>(builder: widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = SplashMetrics.scaleFor(media.size);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const SplashBackdrop(),

          // The glow sits behind the card and is centred on the logo, which is
          // centred in the card — so it gets its own translated layer.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, SplashMetrics.cardCentreDy * scale),
                child: ConnectionGlow(
                  scale: scale,
                  opacity: _motion.glowOpacity,
                  glowScale: _motion.glowScale,
                ),
              ),
            ),
          ),

          // Card + wordmark travel together as one block.
          Center(
            child: Transform.translate(
              offset: Offset(0, SplashMetrics.lockupCentreDy * scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LogoCard(motion: _motion, scale: scale),
                  SizedBox(height: SplashMetrics.cardToWordmarkGap * scale),
                  FinixWordmark(motion: _motion, scale: scale),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            // The design's 50 px inset already clears an iPhone home bar, but
            // respect the real inset on devices where it does not.
            bottom: math.max(
              SplashMetrics.versionBottomInset * scale,
              media.viewPadding.bottom + 12,
            ),
            child: VersionLabel(
              opacity: _motion.versionOpacity,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}
