import 'package:flutter_svg/flutter_svg.dart';

/// The vectors the splash animates.
///
/// The two links are separate files because each has to assemble on its own
/// path, and because they are the authority on the mark's geometry — the
/// storyboard supplies motion, these supply every edge.
///
/// Names follow the *segments*, not the files: Segment A (light) enters from the
/// card's left and arrives as the right-hand link, so its art is
/// `right_chain.svg`. Segment B (dark) does the mirror.
///
/// The card is not an asset — it is drawn in Flutter so its shadows can be
/// expressed as real `BoxShadow`s rather than a baked SVG filter.
abstract class SplashAssets {
  static const _dir = 'assets/splash';

  /// Light `#B9C3D1`, upper, ends as the right-hand link.
  static const segmentA = '$_dir/right_chain.svg';

  /// Dark `#0A1628`, lower, ends as the left-hand link.
  static const segmentB = '$_dir/left_chain.svg';

  static const wordmark = '$_dir/finix_wordmark.svg';

  static const all = <String>[segmentA, segmentB, wordmark];

  /// Parses and caches the vectors before the timeline starts, so nothing pops
  /// in mid-assembly.
  ///
  /// `loadBytes` populates `svg.cache` itself, keyed on the asset and the root
  /// bundle — the same key `SvgPicture.asset` will look up — so this is both
  /// idempotent and effective.
  static Future<void> precache() => Future.wait(
        all.map((asset) => SvgAssetLoader(asset).loadBytes(null)),
      );
}
