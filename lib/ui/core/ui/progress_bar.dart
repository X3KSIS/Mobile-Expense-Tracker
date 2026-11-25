import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';

/// Rounded horizontal progress bar. [value] is a fraction and is clamped
/// to 0–1 for drawing.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.accent,
    this.trackColor = AppColors.surfaceMuted,
    this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimens.radiusFull),
        child: SizedBox(
          height: Dimens.progressBarHeight,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: trackColor)),
              // Grows from empty on first show, then eases to new values.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: target),
                duration: AppMotion.long,
                curve: AppMotion.move,
                builder: (context, fraction, child) => FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(Dimens.radiusFull),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
