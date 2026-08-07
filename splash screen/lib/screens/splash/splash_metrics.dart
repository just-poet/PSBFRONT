import 'dart:math' as math;
import 'dart:ui' show Size;

/// Layout for the splash screen.
///
/// Card, wordmark and label placement come from `Splash screen.svg` (a 390 x 844
/// frame). The logo's placement inside the card comes from
/// `Background+Shadow.svg`. Segment motion lives in `splash_motion.dart`;
/// segment shape lives in `segment_geometry.dart`.
///
/// Every value is in *design units* — multiply by [scaleFor] for logical pixels.
abstract class SplashMetrics {
  // ── Design frame ──────────────────────────────────────────────────────────
  static const designWidth = 390.0;
  static const designHeight = 844.0;

  /// Clamped so the mark never becomes a postage stamp on a small phone or a
  /// billboard on a tablet.
  static const minScale = 0.85;
  static const maxScale = 1.6;

  /// Driven by the *shortest* side so a landscape phone scales like a portrait
  /// one instead of blowing the lockup up to fill the width.
  static double scaleFor(Size viewport) =>
      (math.min(viewport.width, viewport.height) / designWidth)
          .clamp(minScale, maxScale);

  // ── Logo card ─────────────────────────────────────────────────────────────
  static const cardWidth = 122.0;
  static const cardHeight = 121.0;
  static const cardRadius = 22.0;

  /// y of the card's top edge in the design frame.
  static const cardTop = 308.5;

  /// The design's two stacked drop shadows, as Gaussian sigmas (SVG
  /// `stdDeviation`) rather than Flutter's `blurRadius`. `03.4` asks for soft
  /// shadows only, which is what these are.
  static const shadowNearSigma = 4.0;
  static const shadowNearDy = 4.0;
  static const shadowNearAlpha = 0.10;
  static const shadowFarSigma = 16.0;
  static const shadowFarDy = 16.0;
  static const shadowFarAlpha = 0.20;

  // ── Logo box inside the card ──────────────────────────────────────────────
  /// From `Background+Shadow.svg`: the 64 x 30.877 logo sits at this offset
  /// inside the card.
  static const logoLeft = 29.0;
  static const logoTop = 45.0614;
  static const logoWidth = 64.0;
  static const logoHeight = 30.8771;

  /// Segment B's art box starts at the logo box's left edge; Segment A's is
  /// inset by this much. (Their 43-wide boxes overhang the 64-wide logo box by
  /// 0.87 units of empty space, which is why the segment Stack does not clip.)
  static const segmentBInset = 0.0;
  static const segmentAInset = 21.8688;

  // ── Wordmark ──────────────────────────────────────────────────────────────
  //
  // One deliberate deviation from the export: in `Splash screen.svg` the
  // wordmark's ink sits ~2.9 px right of the frame's centre line while the card
  // is dead centre. That reads as a nudge that got left in, and it would drift
  // at other widths, so the wordmark is centred here instead.
  static const wordmarkWidth = 61.0;
  static const wordmarkHeight = 28.0;

  /// y of the wordmark's top edge in the design frame.
  static const wordmarkTop = 468.08;

  static const cardToWordmarkGap =
      wordmarkTop - (cardTop + cardHeight); // 38.58

  /// Card + gap + wordmark: the block that gets centred on screen.
  static const lockupHeight = cardHeight + cardToWordmarkGap + wordmarkHeight;

  /// Offsets from the viewport centre. The design sits slightly high — anchor
  /// off the centre rather than the top edge so tall and short screens both
  /// keep the mark in the same optical position.
  static const cardCentreDy =
      (cardTop + cardHeight / 2) - designHeight / 2; // -53.0
  static const lockupCentreDy =
      (cardTop + lockupHeight / 2) - designHeight / 2; // -19.71

  /// `03.4`: the wordmark fades *upward slightly*. `06`: +6 px -> 0.
  static const wordmarkRise = 6.0;

  // ── Connection glow (frame 7) ─────────────────────────────────────────────
  /// `06`: blur 18 px, opacity 20 %, scale 100 -> 125 -> 100, Finix blue.
  /// `03.4`: it supports the logo and never dominates it, so it is sized to the
  /// logo box rather than the card.
  static const glowBlur = 18.0;
  static const glowOpacity = 0.20;
  static const glowScale = 1.25;

  /// `06`: pulse peak 1.025.
  static const pulseScale = 1.025;

  // ── Version label ─────────────────────────────────────────────────────────
  //
  // Not in any storyboard frame, but present in the approved final screen. The
  // storyboard governs the motion; `Splash screen.svg` governs the composition,
  // so it stays and arrives with the wordmark.
  static const versionFontSize = 11.0;
  static const versionLetterSpacing = 0.2;

  /// Design distance from the label's box to the bottom of the frame.
  static const versionBottomInset = 50.0;
}
