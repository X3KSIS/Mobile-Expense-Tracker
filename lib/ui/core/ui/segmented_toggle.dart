import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';

/// One option in a [SegmentedToggle].
class ToggleOption<T> {
  const ToggleOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill-shaped segmented control: a muted track with a navy thumb that
/// slides to the selected option while the labels cross-fade colour.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ToggleOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == selected);
    final count = options.length;
    // Alignment.x runs -1..1 across the track.
    final thumbX = count == 1 ? 0.0 : -1 + 2 * index / (count - 1);
    return Container(
      height: Dimens.minTouchTarget + Dimens.gapXs * 2,
      padding: const EdgeInsets.all(Dimens.gapXs),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(Dimens.radiusFull),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(thumbX, 0),
            duration: AppMotion.long,
            curve: AppMotion.move,
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppColors.navy,
                  shape: StadiumBorder(),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: _Segment(
                    label: option.label,
                    selected: option.value == selected,
                    onTap: () => onChanged(option.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              curve: AppMotion.move,
              style: AppTypography.button.copyWith(
                color: selected
                    ? AppColors.textOnNavy
                    : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
