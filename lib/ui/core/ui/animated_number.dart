import 'package:flutter/widgets.dart';

import '../themes/motion.dart';

/// Counts smoothly from the previous [value] to the new one, so totals
/// and counts roll to their new figure instead of snapping.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, required this.builder});

  final double value;

  /// Builds the display for the in-between value.
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: AppMotion.long,
      curve: AppMotion.move,
      builder: (context, v, _) => builder(context, v),
    );
  }
}
