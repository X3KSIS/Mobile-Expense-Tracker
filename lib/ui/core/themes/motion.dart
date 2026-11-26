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

  /// Light and dark themes blending into each other.
  static const Duration theme = Duration(milliseconds: 500);

  /// Icons morphing from one shape into another, e.g. sun to moon.
  static const Duration morph = Duration(milliseconds: 560);

  /// Cards expanding and collapsing. Always paired with [expandCurve].
  static const Duration expand = Duration(milliseconds: 350);

  /// Ease out: expansion starts quickly and settles gently.
  static const Curve expandCurve = Curves.easeOut;

  /// Pressed buttons shrink to this scale, then spring back.
  static const double pressScale = 0.95;

  /// How quickly a pressed button shrinks.
  static const Duration pressDown = Duration(milliseconds: 90);

  /// Spring that brings a pressed button back to full size with a small,
  /// soft overshoot.
  static const SpringDescription pressSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 18,
  );

  /// A dragged list item grows by 5 % while it is lifted.
  static const double dragLiftScale = 1.05;

  /// Pull-to-refresh runs in slow motion: the indicator eases open, spins
  /// slowly while refreshing, and settles back over these durations.
  static const Duration refreshSettle = Duration(milliseconds: 900);
  static const Duration refreshSpin = Duration(milliseconds: 1800);

  /// Slow, gentle easing for the pull-to-refresh indicator.
  static const Curve slowMotion = Curves.easeInOutSine;

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
