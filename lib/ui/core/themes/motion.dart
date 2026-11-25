import 'package:flutter/animation.dart';

/// Motion tokens. Every animated change in the app uses these so nothing
/// appears or disappears suddenly and everything moves with the same feel.
abstract final class AppMotion {
  /// Small state changes: icons, colours, selection rings.
  static const Duration short = Duration(milliseconds: 180);

  /// Content swaps: loading to content, filters, months.
  static const Duration medium = Duration(milliseconds: 280);

  /// Larger movement: nav pill, page transitions, bars growing.
  static const Duration long = Duration(milliseconds: 420);

  /// Shimmer sweep across skeletons.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Things arriving or settling.
  static const Curve enter = Curves.easeOutCubic;

  /// Things moving from one place to another.
  static const Curve move = Curves.easeInOutCubic;

  /// Fade-through: the outgoing content is gone in the first 35 % of the
  /// transition, and the incoming content fades in over the rest, so the
  /// two never overlap into a muddy blend.
  static const Curve fadeThroughIn = Interval(0.35, 1, curve: Curves.easeOut);

  /// For a forward animation running 1 to 0 (e.g. AnimatedOpacity going
  /// out): reaches 0 after the first 35 % of the time.
  static const Curve fadeThroughOutForward = Interval(
    0,
    0.35,
    curve: Curves.easeIn,
  );

  /// For an AnimatedSwitcher's outgoing child, whose animation runs in
  /// reverse: reaches 0 after the first 35 % of the time.
  static const Curve fadeThroughOutReverse = Interval(
    0.65,
    1,
    curve: Curves.easeIn,
  );
}
