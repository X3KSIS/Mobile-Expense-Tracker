import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/ui/progress_bar.dart';

/// A budget's progress bar with a thin "today" marker where spending would
/// be at an even pace through the cycle, so a glance shows whether the
/// budget is running ahead of time.
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.value,
    required this.planned,
    required this.markerColor,
    required this.semanticLabel,
    this.color,
    this.trackColor,
  });

  /// Share of the limit spent, 0 to 1 (more is clamped).
  final double value;

  /// Share of the cycle gone by today, 0 to 1.
  final double planned;
  final Color markerColor;
  final String semanticLabel;
  final Color? color;
  final Color? trackColor;

  static const double _markerWidth = 2;
  static const double _overhang = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: Dimens.progressBarHeight + _overhang * 2,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final left = (width * planned.clamp(0, 1) - _markerWidth / 2).clamp(
              0.0,
              width - _markerWidth,
            );
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: _overhang,
                  child: ProgressBar(
                    value: value,
                    color: color,
                    trackColor: trackColor,
                  ),
                ),
                AnimatedPositioned(
                  duration: AppMotion.medium,
                  curve: AppMotion.move,
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: _markerWidth,
                    decoration: BoxDecoration(
                      color: markerColor,
                      borderRadius: BorderRadius.circular(_markerWidth),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
