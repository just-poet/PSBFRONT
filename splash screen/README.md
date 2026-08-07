# FINIX Splash Screen Animation — Handover

Self-contained Flutter implementation of the approved FINIX splash storyboard.
3 000 ms, one `AnimationController`, ending in a cross-fade to your app.

Verified standalone: dropped into an empty `flutter create` project it analyzes
with zero issues, its 11 tests pass, and it renders. Built against **Flutter
3.41.6 / Dart 3.11.4**, `flutter_svg` **2.3.0**. Measured on a Nothing Phone (3)
at 120 Hz on Impeller/Vulkan.

---

## 1. Install

**Copy `lib/` and `assets/` into your project root**, merging with what's there.

```
lib/
  screens/
    splash_screen.dart          ← the screen; owns the controller
    splash/
      splash_motion.dart        ← the timeline (storyboard frame times + tweens)
      splash_metrics.dart       ← layout, from Splash screen.svg
      segment_geometry.dart     ← segment shape, from the chain vectors
      logo_card.dart            ← the navy card
      logo_segments.dart        ← the two animating links
      background_glow.dart      ← backdrop wash + frame-7 connection glow
      finix_wordmark.dart       ← "finix"
      version_label.dart        ← the build string
      splash_assets.dart        ← asset paths + precache
  widgets/
    fade_page_route.dart        ← the hand-off route
  theme/
    finix_theme.dart            ← ⚠ see §3
assets/
  splash/{left_chain,right_chain,finix_wordmark}.svg
  fonts/GeistMono.ttf
test/
  splash_animation_test.dart    ← optional, but see §7
```

**Add to `pubspec.yaml`:**

```yaml
dependencies:
  flutter_svg: ^2.0.17

flutter:
  uses-material-design: true

  assets:
    - assets/splash/

  fonts:
    - family: Geist Mono
      fonts:
        - asset: assets/fonts/GeistMono.ttf
```

Then `flutter pub get`.

---

## 2. Use it

`nextScreen` is the only thing you must supply.

```dart
import 'package:flutter/material.dart';
import 'screens/splash/splash_assets.dart';
import 'screens/splash_screen.dart';
import 'theme/finix_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Parses the vectors before the first frame so nothing pops in mid-assembly.
  await SplashAssets.precache();
  runApp(const FinixApp());
}

class FinixApp extends StatelessWidget {
  const FinixApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: finixTheme(),
        home: SplashScreen(nextScreen: (_) => const HomeDashboardScreen()),
      );
}
```

Need to pick the destination at runtime (onboarding vs. dashboard, auth check)?
Pass `onFinished` instead — it replaces the hand-off entirely and you navigate
yourself:

```dart
SplashScreen(
  nextScreen: (_) => const SizedBox(),   // unused when onFinished is set
  onFinished: () => Navigator.of(context).pushReplacement(...),
)
```

The splash does **not** wait on your app's startup work. If you need it to,
`await` that work in `main()` before `runApp`, or drive it in parallel and gate
inside `onFinished`.

---

## 3. The one file to check: `lib/theme/finix_theme.dart`

This is a **minimal subset** of the FINIX design system — only the six colours
and the one text style the splash uses.

**If your project already has `lib/theme/finix_theme.dart`, delete the one in
this package and keep yours.** The class and member names match the full design
system exactly, so no other file needs editing.

What the splash consumes from it:

| Token | Value | Used for |
|---|---|---|
| `FinixColors.navy` | `#0B2545` | card shadow |
| `FinixColors.trust` | `#13315C` | card gradient, dark end |
| `FinixColors.action` | `#2E75B6` | card sheen, backdrop wash, glow |
| `FinixColors.cloud` | `#F8FAFC` | screen surface |
| `FinixColors.ink` | `#0A1628` | Segment B (the dark link) |
| `FinixColors.mist` | `#94A3B8` | version label |
| `FinixText.mono(...)` | Geist Mono | version label |

The screen reads its background from
`Theme.of(context).scaffoldBackgroundColor`, so whatever theme you pass must set
it. `#4B81C4` (the card gradient's light end) and `#B9C3D1` (Segment A) are
deliberately **not** tokens — they belong to the mark, and live as private
constants in `logo_card.dart` and `logo_segments.dart`.

---

## 4. Two things to wire up

**The version label** defaults to `'v 0.1.4 · build 143'`, transcribed from the
approved design. Feed it from `package_info_plus` rather than shipping a frozen
string:

```dart
VersionLabel(opacity: ..., scale: ..., label: 'v $version · build $build')
```

**Status bar.** The splash is light, so set dark icons before `runApp`:

```dart
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
));
```

---

## 5. How it works, in one page

Each of the two logo halves is **its own vector clipped to a swept region**. The
storyboard supplies *how far along its link's perimeter the body has travelled*;
`left_chain.svg` / `right_chain.svg` supply every edge, thickness, corner radius
and notch. Nothing is redrawn, and at frame 7 the clip admits the whole vector —
so the final mark is the supplied artwork, exactly.

Segment A (light) enters top-left → right along the top arm → down the right arm
→ left along the bottom arm → up the left arm, arriving as the **right-hand**
link. Segment B (dark) is that motion **rotated 180° about the logo's centre**,
which is precisely how the two links relate in `logo.svg`. So one schedule drives
both, and they cannot drift apart.

They never overlap until the interlock: each shares a row with the other but
holds the opposite end of it, and the tails retreat to keep clear. That is the
storyboard's own choreography — hence no storyboard frame shows one crossing the
other.

### Timeline

| Time | Frame | What happens |
|---|---|---|
| 0–300 ms | 1 | card fades up; both segments already travelling in, clipped by the card |
| 300 ms | 2 | interpolated — see below |
| 850 ms | 3 | each leading end has turned: A down, B up |
| 1400 ms | 4 | side arms at full height |
| 1750 ms | 5 | two C's facing each other |
| 2050 ms | 5.5 | thread-through; closing stubs grow |
| 2250 ms | 6 | almost interlocked |
| 2550 ms | 7 | complete. Pulse 1.00→1.025→1.00 (150 ms), one glow (250 ms), wordmark +6 px fade (250 ms) |
| 2800–3000 ms | — | hold |
| 3000 ms | — | `FadeTransition` to `nextScreen` |

**`2.svg` was never drawn.** Frames 1→3 are a single rigid translation — both
ends advance 89.06 units — so linear interpolation across that leg reproduces
frame 2 without inventing a pose. There is a test for it.

**Responsive.** Everything is in design units against a 390 × 844 frame,
multiplied by one `scale` derived from the viewport's *shortest* side and clamped
to 0.85–1.6. Nothing is hardcoded to a screen size.

---

## 6. Please don't "improve" these

Per specification docs `03.5` and `03.6`, the following are **prohibited** and
were deliberately removed from an earlier draft. Re-adding them breaks approval:

- ❌ overshoot, bounce, elastic, spring, `easeOutBack` — including the old 2 px
  chain overshoot and `elasticOut` settle
- ❌ the glass shimmer / `ShaderMask` sweep (a test asserts no `ShaderMask` is
  ever drawn)
- ❌ card materialisation — the card is identical in all seven storyboard frames,
  so it only fades; it does not scale, rise, or grow its shadow
- ❌ an emerging ambient glow, or any breathing/idle loop
- ❌ SVG path morphing, stretch, squash, warp
- ❌ loading spinners, progress bars, particles, rotations

The glow appears **only after the mark is complete**, and the wordmark **after
that**. Nothing celebrates early.

**Design authority when specs disagree:** the storyboard frames define
**motion**; the SVG vectors define **geometry**. The frames were drawn by hand
and are approximations in places — they run ~0.7 units thicker than the mark's
arms, with square corners and one stub 3.5 units off. Take timing and travel
distance from the frames; take every edge from the vectors. Priority order:
storyboard (`01`, `03.x`) → vectors → motion spec → blueprint (`04`).
`Finix_Motion_Design_Specification_v2.md` is **superseded**.

---

## 7. Tests

`test/splash_animation_test.dart` is pure Dart — no rendering, no assets, no
fonts, runs anywhere:

```bash
flutter test test/splash_animation_test.dart
```

11 tests. They assert every storyboard frame time hits its keyframe, that body
length is constant through the entry, that the pulse peaks at exactly 1.025 and
**never dips below 1.0** (no overshoot), that glow and wordmark are zero at every
point before 2550 ms, and that frame 7's clip admits every sampled point of the
link's four arms. Change a number in `splash_motion.dart` and they tell you which
frame you broke.

The imports are relative so the file compiles whatever your package is called;
swap them for `package:<your_app>/...` if you prefer.

---

## 8. Performance, and one known issue

Measured on a Nothing Phone (3), Android 16, 120 Hz, Impeller/Vulkan, profile
build, ~397 frames per run:

| | median | p90 | p99 |
|---|---|---|---|
| build | **0.35 ms** | 0.85 | 1.17 |
| raster | 1.80 ms | 2.88 | 5.0 |
| total span | **3.0 ms** | 4.0–5.0 | 5.1–6.0 |

Budget at 120 Hz is 8.33 ms. During the animation, 2 frames of 343 exceed it. The
0.35 ms median build time is the design working: `*Transition` widgets and
`CustomPainter(repaint:)` repaint without rebuilding any widget, and the vectors
are built once and passed as `child`.

> **Known issue — one dropped frame at 2550 ms.** Reproducible across runs at
> 21.8 ms and 24.4 ms, raster-bound. Three things first-rasterise on that single
> frame: the glow's blur, the wordmark's SVG, and the pulse's scale layer. Doc
> `06` sets a zero-dropped-frame target, so this is an open miss — at the most
> visible moment of the animation.
>
> Cheapest fix: rasterise the glow and wordmark at ~1/255 alpha for a few frames
> before 2550 so the cost lands on an earlier cheap frame. Nothing visible
> changes and no spec value moves. `ConnectionGlow` currently returns
> `SizedBox.shrink()` at zero alpha, so nothing warms.

Other notes:

- The shadow blur values convert SVG `stdDeviation` into Flutter's `blurRadius`
  (`sigma = radius * 0.57735 + 0.5`, inverted). They are not the same unit —
  don't "simplify" them.
- `flutter_test` forces `debugDisableShadows = true`, so shadows render as hard
  slabs in golden tests. Set it false inside the test body if you golden this.

---

## 9. Deliberate deviations from the exports

Two, both documented in the code:

1. **Wordmark centring.** In `Splash screen.svg` the wordmark's ink sits ~2.9 px
   right of the frame's centre line while the card is dead centre. That reads as
   a nudge left in, and it would drift at other widths, so the wordmark is
   centred.
2. **Logo offset.** Taken from `Background+Shadow.svg` (`y = 45.0614` inside the
   card) rather than by centring the 31-unit art box (`y = 45.0`) — a 0.06 px
   correction.

Reference material lives one folder up: the storyboard frames (`1.svg`, `3.svg`,
`4.svg`, `5.svg`, `5.5.svg`, `6.svg`, `7.svg`), `Splash screen.svg`,
`Background+Shadow.svg`, and `logo.svg`.
