import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

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
    final fraction = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
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
              FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
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
