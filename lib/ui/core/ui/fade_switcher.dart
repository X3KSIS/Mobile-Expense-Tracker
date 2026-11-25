import 'package:flutter/material.dart';

import '../themes/motion.dart';

/// Fades through (old content out, then new content in with a slight
/// upward drift) whenever [child] changes
/// identity, and smoothly resizes to the new child's height. Give the child
/// a [Key] that changes when the content should be treated as new, e.g.
/// `ValueKey(month)`.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.medium,
    this.alignment = Alignment.topCenter,
    this.animateSize = true,
  });

  final Widget child;
  final Duration duration;
  final Alignment alignment;

  /// Smoothly resize between children. Turn off for full-screen swaps
  /// (e.g. skeleton to a scrolling page), which always fill their parent.
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.fadeThroughIn,
      switchOutCurve: AppMotion.fadeThroughOutReverse,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        fit: animateSize ? StackFit.loose : StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
    if (!animateSize) return switcher;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.move,
      alignment: alignment,
      child: switcher,
    );
  }
}
