import 'dart:math' as math;
import 'dart:ui';

/// Arc-length geometry of one animated logo segment, derived from the approved
/// storyboard frames (`1.svg`, `3.svg`, `4.svg`, `5.svg`, `5.5.svg`, `6.svg`,
/// `7.svg`) and the supplied chain vectors.
///
/// ## What the storyboard encodes
///
/// Each segment is a constant-thickness bar travelling along the *perimeter of
/// its own final link*. Measured across all seven frames (all 1:1 with the same
/// 122 x 121 card), Segment A enters at the card's top-left, runs right along
/// the top arm, turns down the right arm, runs left along the bottom arm, then
/// turns up the left arm — arriving as the finished right-hand link. Segment B
/// is that same motion rotated 180 degrees about the logo's centre, which is
/// exactly how the two links relate to each other in `logo.svg`.
///
/// So one arc-length parameterisation drives both segments; [mirrored] selects
/// which. That also guarantees the simultaneity `03.3` and `03.4` require —
/// the two segments cannot drift apart, because they share one schedule.
///
/// ## Coordinates
///
/// Everything below is in *link-local design units*: the coordinate space of
/// `left_chain.svg` / `right_chain.svg`, whose 43 x 31 art box holds content
/// spanning [contentWidth] x [contentHeight]. Multiply by a scale factor for
/// logical pixels.
///
/// `s` is arc length along the segment's path, with `s = 0` at the outer end of
/// the entry arm. The landmark values below are not chosen — they fall out of
/// the link's own geometry, and the storyboard's measured head positions land
/// on them to within 0.1 units, which is what confirms this reading.
abstract class SegmentPath {
  /// Ink extents of the chain art inside its 43 x 31 box.
  static const contentWidth = 42.1312;
  static const contentHeight = 30.8771;

  /// Art-box size as authored, for sizing the `SvgPicture`.
  static const artBoxWidth = 43.0;
  static const artBoxHeight = 31.0;

  // ── Arm centrelines (Segment A, in its own art box) ──────────────────────
  static const topRowY = 3.105; // top arm spans y 0 .. 6.209
  static const rightColX = 38.757; // right arm spans x 35.383 .. 42.131
  static const bottomRowY = 27.821; // bottom arm spans y 24.765 .. 30.877
  static const stubX = 3.375; // left arm spans x 0 .. 6.750

  // ── Arc length at each turn ──────────────────────────────────────────────
  static const sTopToRight = 38.757;
  static const sRightToBottom = 63.473;
  static const sBottomToStub = 98.855;

  /// End of the path: the far tip of the left arm.
  static const sEnd = 114.913;

  /// Where the link's own outline begins — its outer top-left corner. The
  /// storyboard's frame-7 tail sits exactly here, which is why the segment
  /// stops travelling at this point rather than anywhere else.
  static const sLinkStart = 18.899;

  /// Where the top arm reaches full thickness. Between [sLinkStart] and here
  /// the link tapers, because in the finished mark this is where one link
  /// emerges from behind the other.
  static const sNotchEnd = 22.590;

  /// Exact inner edge of the entry arm, so the entry bar butts seamlessly
  /// against the link's own arm.
  static const entryArmThickness = 6.209;

  /// The four arms, in travel order.
  static const _arms = <_Arm>[
    // Entry arm. `sFrom` reaches far outside the card so the segment can
    // travel in from off-screen; the card's own ClipRRect trims it.
    _Arm(
      vertical: false,
      bandLow: -1.5,
      bandHigh: 7.6,
      sFrom: -400,
      sTo: sTopToRight,
      at: -400,
      dir: 1,
    ),
    _Arm(
      vertical: true,
      bandLow: 34.0,
      bandHigh: 43.6,
      sFrom: sTopToRight,
      sTo: sRightToBottom,
      at: topRowY,
      dir: 1,
    ),
    _Arm(
      vertical: false,
      bandLow: 23.5,
      bandHigh: 32.4,
      sFrom: sRightToBottom,
      sTo: sBottomToStub,
      at: rightColX,
      dir: -1,
    ),
    _Arm(
      vertical: true,
      bandLow: -1.5,
      bandHigh: 8.3,
      sFrom: sBottomToStub,
      sTo: sEnd,
      at: bottomRowY,
      dir: -1,
    ),
  ];

  /// Square patches filling each turn, admitted once the head reaches it.
  ///
  /// The arm bands alone leave the outer corner of each turn uncovered, since
  /// neither adjacent arm's extent crosses it. There is no matching gate for
  /// the tail: the tail's final resting position ([sLinkStart]) is short of the
  /// first turn, so it never reaches one.
  static const _corners = <_Corner>[
    _Corner(gate: sTopToRight, rect: Rect.fromLTRB(34.0, -1.5, 43.6, 7.6)),
    _Corner(gate: sRightToBottom, rect: Rect.fromLTRB(34.0, 23.5, 43.6, 32.4)),
    _Corner(gate: sBottomToStub, rect: Rect.fromLTRB(-1.5, 23.5, 8.3, 32.4)),
  ];

  /// The region of the link revealed for the body between [tail] and [head].
  ///
  /// Intersected with the link's own outline (by clipping the SVG to it), this
  /// yields the segment: the logo's exact arm thicknesses, corner radii and
  /// notches, with no geometry redrawn.
  ///
  /// Rectangles are unioned by overlapping them in one non-zero path, so no
  /// boolean path op runs per frame.
  static Path sweep({
    required double tail,
    required double head,
    required bool mirrored,
    required double scale,
  }) {
    final path = Path();
    for (final arm in _arms) {
      final from = math.max(tail, arm.sFrom);
      final to = math.min(head, arm.sTo);
      if (to <= from) continue;
      final a = arm.at + arm.dir * (from - arm.sFrom);
      final b = arm.at + arm.dir * (to - arm.sFrom);
      final low = math.min(a, b);
      final high = math.max(a, b);
      path.addRect(_map(
        arm.vertical
            ? Rect.fromLTRB(arm.bandLow, low, arm.bandHigh, high)
            : Rect.fromLTRB(low, arm.bandLow, high, arm.bandHigh),
        mirrored,
        scale,
      ));
    }
    for (final corner in _corners) {
      if (head >= corner.gate) path.addRect(_map(corner.rect, mirrored, scale));
    }
    return path;
  }

  /// The part of the segment that lies *outside* its link's outline — the body
  /// that has entered the card but not yet reached the link's own geometry.
  ///
  /// Returns null once the segment is entirely within the link.
  ///
  /// [notchEnd] is where this bar stops. It runs from [sNotchEnd] (bar covers
  /// the taper, so the segment reads as a plain square-ended bar, as frames
  /// 1-4 draw it) down to [sLinkStart] (bar gone, the link's notch exposed, as
  /// frame 7 draws it). Frames 5, 5.5 and 6 draw a partial chamfer here, which
  /// is what that travel reproduces.
  static Rect? entryBar({
    required double tail,
    required double head,
    required double notchEnd,
    required bool mirrored,
    required double scale,
  }) {
    final to = math.min(head, notchEnd);
    if (to <= tail) return null;
    return _map(
      Rect.fromLTRB(tail, 0, to, entryArmThickness),
      mirrored,
      scale,
    );
  }

  /// Segment B is Segment A rotated 180 degrees about the link's centre.
  static Rect _map(Rect rect, bool mirrored, double scale) {
    final oriented = mirrored
        ? Rect.fromLTRB(
            contentWidth - rect.right,
            contentHeight - rect.bottom,
            contentWidth - rect.left,
            contentHeight - rect.top,
          )
        : rect;
    return Rect.fromLTRB(
      oriented.left * scale,
      oriented.top * scale,
      oriented.right * scale,
      oriented.bottom * scale,
    );
  }
}

class _Arm {
  const _Arm({
    required this.vertical,
    required this.bandLow,
    required this.bandHigh,
    required this.sFrom,
    required this.sTo,
    required this.at,
    required this.dir,
  });

  /// True when the body extends along y, false when it extends along x.
  final bool vertical;

  /// Bounds across the arm's thickness, generous enough to cover it fully
  /// while staying clear of the neighbouring arms.
  final double bandLow;
  final double bandHigh;

  final double sFrom;
  final double sTo;

  /// Coordinate along the extent axis at [sFrom].
  final double at;

  /// Travel direction along the extent axis: 1 or -1.
  final double dir;
}

class _Corner {
  const _Corner({required this.gate, required this.rect});

  final double gate;
  final Rect rect;
}
