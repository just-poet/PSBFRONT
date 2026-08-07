import 'package:flutter/animation.dart';

import 'segment_geometry.dart';
import 'splash_metrics.dart';

/// The approved storyboard timeline, in milliseconds from the first frame.
///
/// Times are from `03.5` and `06`. One controller drives all of it, so these
/// numbers are the single source of truth for *when* anything happens.
abstract class SplashPhases {
  static const totalMs = 3000;
  static const total = Duration(milliseconds: totalMs);

  /// Frame times. Frame 2 (300 ms) is deliberately absent: `2.svg` was never
  /// drawn, and frames 1 -> 3 are a single rigid translation (both ends advance
  /// 89.06 units), so linear interpolation across that leg reproduces frame 2
  /// without inventing a pose.
  static const frame1 = 0;
  static const frame3 = 850;
  static const frame4 = 1400;
  static const frame5 = 1750;
  static const frame55 = 2050;
  static const frame6 = 2250;
  static const frame7 = 2550;

  static const frameTimes = <int>[
    frame1,
    frame3,
    frame4,
    frame5,
    frame55,
    frame6,
    frame7,
  ];

  /// The card is drawn in every storyboard frame, so it does not materialise —
  /// it only fades up, at full scale and position, before the segments arrive.
  static const cardFadeEnd = 300;

  /// `03.4`: the confirmation pulse fires "immediately after interlock", and
  /// interlock is only geometrically true at frame 7. `06`: 150 ms.
  static const pulseStart = frame7;
  static const pulseEnd = 2700;

  /// `03.4` / `06`: glow and wordmark follow completion, 250 ms each.
  static const revealStart = frame7;
  static const revealEnd = 2800;

  /// `03.4`: hold long enough to read the brand before navigating.
  static const holdEnd = totalMs;
}

/// Every animated value the splash needs, derived once from a single
/// [AnimationController] whose duration is [SplashPhases.total].
///
/// Building these in `initState` rather than in `build` means no tween is
/// allocated per frame, and the widgets downstream can use the
/// `*Transition` widgets, which repaint without rebuilding any widget.
class SplashAnimations {
  SplashAnimations(this.controller) {
    // ── The segments ────────────────────────────────────────────────────────
    //
    // Arc-length positions of the body's two ends, in link-local units, read
    // off the storyboard frames. Segment A and Segment B were measured
    // separately and agree to within ~4 units; since `03.3` and `03.4` require
    // them to move together and complete simultaneously, the two readings are
    // averaged into this one schedule and Segment B mirrors it.
    //
    // The values land on the link's own structural landmarks, which is what
    // confirms the reading:
    //   frame 4 head  63.47  ==  the bottom-right turn      (63.473)
    //   frame 7 head 114.91  ==  the far tip of the arm     (114.913)
    //   frame 7 tail  18.90  ==  where the link's outline begins (18.899)
    segmentTail = _keyframed(const [
      -131.13, // frame 1   off-card, clipped by the card
      -42.07, //  frame 3
      -9.73, //   frame 4
      15.87, //   frame 5
      20.91, //   frame 5.5
      20.82, //   frame 6
      SegmentPath.sLinkStart, // frame 7
    ]);
    segmentHead = _keyframed(const [
      -38.88, //  frame 1
      50.18, //   frame 3
      SegmentPath.sRightToBottom, // frame 4
      94.68, //   frame 5
      107.63, //  frame 5.5
      114.62, //  frame 6
      SegmentPath.sEnd, // frame 7
    ]);

    // The tail's chamfer. Frames 1-4 draw a square end; 5, 5.5 and 6 draw a
    // partial bevel; frame 7 is the link's own tapered notch. Held square until
    // frame 4, then travelled to the notch.
    notchFill = _keyframed(const [
      SegmentPath.sNotchEnd,
      SegmentPath.sNotchEnd,
      SegmentPath.sNotchEnd,
      21.67,
      20.72,
      20.09,
      SegmentPath.sLinkStart,
    ]);

    // ── The card ────────────────────────────────────────────────────────────
    cardOpacity = _window(0, SplashPhases.cardFadeEnd, Curves.easeInOutCubic);

    // ── Frame 7: confirmation pulse on the logo, not the card ───────────────
    //
    // `06` names easeOutBack, but `03.5` forbids Back and overshoot outright
    // and names easeOutCubic for the pulse. `03.5` is the storyboard document,
    // so it wins; a 1.00 -> 1.025 -> 1.00 pair needs no overshoot anyway.
    segmentPulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: SplashPhases.pulseStart.toDouble()),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: SplashMetrics.pulseScale)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: SplashMetrics.pulseScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 90,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: (SplashPhases.totalMs - SplashPhases.pulseEnd).toDouble(),
      ),
    ]).animate(controller);

    // ── Frame 7: connection glow, one pass ──────────────────────────────────
    final reveal = _window(
      SplashPhases.revealStart,
      SplashPhases.revealEnd,
      Curves.easeOutCubic,
    );
    glowScale = reveal.drive(
      Tween(begin: 1.0, end: SplashMetrics.glowScale),
    );
    // Sequenced over the whole timeline rather than windowed: a windowed tween
    // would sit at its start value — visible — from the very first frame.
    glowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: SplashPhases.revealStart.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: SplashMetrics.glowOpacity)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween(begin: SplashMetrics.glowOpacity, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 170,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: (SplashPhases.totalMs - SplashPhases.revealEnd).toDouble(),
      ),
    ]).animate(controller);

    // ── Frame 7: wordmark, then the label ───────────────────────────────────
    wordmarkOpacity = reveal;
    wordmarkSlide = reveal.drive(
      Tween(
        begin: const Offset(
          0,
          SplashMetrics.wordmarkRise / SplashMetrics.wordmarkHeight,
        ),
        end: Offset.zero,
      ),
    );
    versionOpacity = reveal;
  }

  final AnimationController controller;

  /// Arc-length positions of the segment body's ends, link-local units.
  /// Segment B uses the same pair, mirrored.
  late final Animation<double> segmentTail;
  late final Animation<double> segmentHead;

  /// Arc length at which the tail's entry bar stops, resolving the chamfer.
  late final Animation<double> notchFill;

  late final Animation<double> cardOpacity;
  late final Animation<double> segmentPulse;

  late final Animation<double> glowScale;
  late final Animation<double> glowOpacity;

  late final Animation<double> wordmarkOpacity;
  late final Animation<Offset> wordmarkSlide;
  late final Animation<double> versionOpacity;

  final List<CurvedAnimation> _windows = [];

  /// A 0 -> 1 value that runs between [fromMs] and [toMs] and holds still
  /// outside that window.
  CurvedAnimation _window(int fromMs, int toMs, [Curve curve = Curves.linear]) {
    final window = CurvedAnimation(
      parent: controller,
      curve: Interval(
        fromMs / SplashPhases.totalMs,
        toMs / SplashPhases.totalMs,
        curve: curve,
      ),
    );
    _windows.add(window);
    return window;
  }

  /// Interpolates one value through [SplashPhases.frameTimes], holding its
  /// final value from frame 7 to the end.
  ///
  /// Legs are linear so the motion never stops between frames — `03.5` forbids
  /// pausing at a keyframe, and a per-leg ease-in-out would do exactly that.
  /// Only the last leg eases out, so the geometry settles into its resting
  /// position rather than arriving at speed (`03.4`: no snapping). The segments
  /// enter from outside the card, so nothing needs to ease *in*.
  Animation<double> _keyframed(List<double> values) {
    assert(values.length == SplashPhases.frameTimes.length);
    final legs = <TweenSequenceItem<double>>[];
    for (var i = 0; i < values.length - 1; i++) {
      final isLast = i == values.length - 2;
      legs.add(TweenSequenceItem(
        tween: Tween(begin: values[i], end: values[i + 1]).chain(
          CurveTween(curve: isLast ? Curves.easeOutCubic : Curves.linear),
        ),
        weight: (SplashPhases.frameTimes[i + 1] - SplashPhases.frameTimes[i])
            .toDouble(),
      ));
    }
    legs.add(TweenSequenceItem(
      tween: ConstantTween(values.last),
      weight: (SplashPhases.totalMs - SplashPhases.frame7).toDouble(),
    ));
    return TweenSequence<double>(legs).animate(controller);
  }

  /// Releases the [CurvedAnimation] listeners. Call from the owner's `dispose`,
  /// before disposing [controller].
  void dispose() {
    for (final window in _windows) {
      window.dispose();
    }
    _windows.clear();
  }
}
