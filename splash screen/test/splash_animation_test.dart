// Relative imports so this file compiles whatever your package is called. If
// you would rather use package imports, swap these two lines for:
//   import 'package:<your_app>/screens/splash/segment_geometry.dart';
//   import 'package:<your_app>/screens/splash/splash_motion.dart';
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/screens/splash/segment_geometry.dart';
import '../lib/screens/splash/splash_motion.dart';

/// Locks the animation to the approved storyboard.
///
/// Pure Dart — no rendering, no assets, no fonts, so it runs anywhere. Change a
/// number in `splash_motion.dart` or `segment_geometry.dart` and these tell you
/// which storyboard frame you broke.
void main() {
  group('storyboard schedule', () {
    late AnimationController controller;
    late SplashAnimations motion;

    setUp(() {
      controller = AnimationController(
        duration: SplashPhases.total,
        vsync: const TestVSync(),
      );
      motion = SplashAnimations(controller);
    });

    tearDown(() {
      motion.dispose();
      controller.dispose();
    });

    void seek(int ms) => controller.value = ms / SplashPhases.totalMs;

    test('segment ends land on the storyboard frames', () {
      const expected = <int, (double, double)>{
        SplashPhases.frame1: (-131.13, -38.88),
        SplashPhases.frame3: (-42.07, 50.18),
        SplashPhases.frame4: (-9.73, SegmentPath.sRightToBottom),
        SplashPhases.frame5: (15.87, 94.68),
        SplashPhases.frame55: (20.91, 107.63),
        SplashPhases.frame6: (20.82, 114.62),
        SplashPhases.frame7: (SegmentPath.sLinkStart, SegmentPath.sEnd),
      };
      expected.forEach((ms, ends) {
        seek(ms);
        expect(motion.segmentTail.value, closeTo(ends.$1, 0.01),
            reason: 'tail at $ms ms');
        expect(motion.segmentHead.value, closeTo(ends.$2, 0.01),
            reason: 'head at $ms ms');
      });
    });

    test('frames 1 to 3 are a rigid translation, so frame 2 needs no keyframe',
        () {
      seek(SplashPhases.frame1);
      final length = motion.segmentHead.value - motion.segmentTail.value;
      for (final ms in [150, 300, 600, SplashPhases.frame3]) {
        seek(ms);
        expect(motion.segmentHead.value - motion.segmentTail.value,
            closeTo(length, 0.01),
            reason: 'body length is constant through the entry, at $ms ms');
      }
    });

    test('the body holds still from frame 7 to the end', () {
      seek(SplashPhases.frame7);
      final tail = motion.segmentTail.value;
      final head = motion.segmentHead.value;
      seek(SplashPhases.totalMs);
      expect(motion.segmentTail.value, closeTo(tail, 0.001));
      expect(motion.segmentHead.value, closeTo(head, 0.001));
    });

    test('nothing celebrates before the mark is complete at frame 7', () {
      for (final ms in [0, 1400, 2250, SplashPhases.frame7 - 1]) {
        seek(ms);
        expect(motion.glowOpacity.value, 0.0, reason: 'glow at $ms ms');
        expect(motion.wordmarkOpacity.value, 0.0, reason: 'wordmark at $ms ms');
        expect(motion.segmentPulse.value, 1.0, reason: 'pulse at $ms ms');
      }
    });

    test('glow runs one pass and the pulse stays subtle', () {
      seek(2600);
      expect(motion.glowOpacity.value, greaterThan(0.0));

      seek(SplashPhases.revealEnd);
      expect(motion.glowOpacity.value, 0.0);

      seek(SplashPhases.totalMs);
      expect(motion.glowOpacity.value, 0.0, reason: 'the glow never returns');

      var peak = 1.0;
      for (var ms = SplashPhases.frame7; ms <= SplashPhases.pulseEnd; ms++) {
        seek(ms);
        final v = motion.segmentPulse.value;
        peak = peak > v ? peak : v;
        expect(v, greaterThanOrEqualTo(1.0),
            reason: 'the pulse never dips below 1.0 — no overshoot');
      }
      expect(peak, closeTo(1.025, 0.001));

      seek(SplashPhases.pulseEnd);
      expect(motion.segmentPulse.value, closeTo(1.0, 0.001));
    });

    test('the card fades up over the first 300 ms and then holds', () {
      seek(0);
      expect(motion.cardOpacity.value, 0.0);
      seek(150);
      expect(motion.cardOpacity.value, greaterThan(0.0));
      seek(SplashPhases.cardFadeEnd);
      expect(motion.cardOpacity.value, 1.0);
      seek(2000);
      expect(motion.cardOpacity.value, 1.0);
    });
  });

  group('segment geometry', () {
    const onTopArm = Offset(28, 3.1);
    const onBottomArm = Offset(20, 27.8);
    const onStub = Offset(3.375, 16);

    Path sweepAt(double tail, double head, {bool mirrored = false}) =>
        SegmentPath.sweep(
          tail: tail,
          head: head,
          mirrored: mirrored,
          scale: 1,
        );

    test('nothing of the link is revealed at frame 1', () {
      final path = sweepAt(-131.13, -38.88);
      expect(path.contains(onTopArm), isFalse);
      expect(path.contains(onBottomArm), isFalse);
      expect(path.contains(onStub), isFalse);
    });

    test('the link is revealed arm by arm, in travel order', () {
      final atFrame4 = sweepAt(-9.73, SegmentPath.sRightToBottom);
      expect(atFrame4.contains(onTopArm), isTrue);
      expect(atFrame4.contains(onBottomArm), isFalse);

      final atFrame5 = sweepAt(15.87, 94.68);
      expect(atFrame5.contains(onBottomArm), isTrue);
      expect(atFrame5.contains(onStub), isFalse,
          reason: 'the head has not turned up the last arm yet');

      final atFrame7 = sweepAt(SegmentPath.sLinkStart, SegmentPath.sEnd);
      expect(atFrame7.contains(onStub), isTrue);
    });

    test('frame 7 reveals the whole vector, so the final mark is exact', () {
      final path = sweepAt(SegmentPath.sLinkStart, SegmentPath.sEnd);
      for (final arm in _linkArms) {
        for (var x = arm.left; x <= arm.right; x += 0.5) {
          for (var y = arm.top; y <= arm.bottom; y += 0.5) {
            expect(path.contains(Offset(x, y)), isTrue,
                reason: 'link ink at ($x, $y) is clipped away');
          }
        }
      }
    });

    test('Segment B is Segment A rotated 180 degrees', () {
      final a = sweepAt(-9.73, SegmentPath.sRightToBottom);
      final b = sweepAt(-9.73, SegmentPath.sRightToBottom, mirrored: true);
      const mirroredTopArm = Offset(
        SegmentPath.contentWidth - 28,
        SegmentPath.contentHeight - 3.1,
      );
      expect(a.contains(onTopArm), isTrue);
      expect(b.contains(onTopArm), isFalse);
      expect(b.contains(mirroredTopArm), isTrue);
    });

    test('the entry bar covers the taper until frame 4, and is gone by 7', () {
      expect(
        SegmentPath.entryBar(
          tail: -131.13,
          head: -38.88,
          notchEnd: SegmentPath.sNotchEnd,
          mirrored: false,
          scale: 1,
        ),
        isNotNull,
        reason: 'the body is outside the link during the entry',
      );
      expect(
        SegmentPath.entryBar(
          tail: SegmentPath.sLinkStart,
          head: SegmentPath.sEnd,
          notchEnd: SegmentPath.sLinkStart,
          mirrored: false,
          scale: 1,
        ),
        isNull,
        reason: "at frame 7 the link's own notch is exposed",
      );
    });
  });
}

/// The four arms of Segment A's link, inset clear of the corner radii and of the
/// notch where the mark's two links pass through each other.
///
/// Each link is a C with an open mouth, not a closed ring — the space inside the
/// mouth is empty, so it must not be sampled.
const _linkArms = <Rect>[
  Rect.fromLTRB(23.0, 0.5, 35.0, 5.7), // top arm, past the notch
  Rect.fromLTRB(36.0, 12.0, 41.6, 19.0), // right arm
  Rect.fromLTRB(8.0, 25.3, 30.0, 30.3), // bottom arm
  Rect.fromLTRB(0.5, 13.0, 6.2, 20.0), // left arm, the closing stub
];
