import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';
import '../view_models/reports_view_model.dart';

/// Calendar of the month with each day shaded by how much was spent, on a
/// single coral ramp (darker is more). Tapping a day shows its total.
class SpendingHeatmap extends StatelessWidget {
  const SpendingHeatmap({
    super.key,
    required this.days,
    required this.selected,
    required this.isFuture,
    required this.onSelected,
  });

  final List<DaySpend> days;
  final DaySpend? selected;
  final bool Function(DateTime day) isFuture;
  final ValueChanged<DateTime> onSelected;

  static const List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Ramp step for [amount]: 0 for nothing, then quartiles of [max].
  static int level(double amount, double max) {
    if (amount <= 0 || max <= 0) return 0;
    return (amount / max * 4).ceil().clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final max = days.fold(0.0, (m, d) => d.amount > m ? d.amount : m);
    final leading = days.first.day.weekday - 1;
    final cells = <DaySpend?>[
      ...List<DaySpend?>.filled(leading, null),
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Readout(selected: selected),
        const SizedBox(height: Dimens.gapM),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    style: context.text.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.gapS - 2),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimens.heatCellGap),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++) ...[
                  if (col > 0) const SizedBox(width: Dimens.heatCellGap),
                  Expanded(child: _cell(cells[row * 7 + col], max)),
                ],
              ],
            ),
          ),
        const SizedBox(height: Dimens.gapS),
        const _Legend(),
      ],
    );
  }

  Widget _cell(DaySpend? day, double max) {
    if (day == null) return const AspectRatio(aspectRatio: 1);
    return _DayCell(
      day: day,
      level: level(day.amount, max),
      future: isFuture(day.day),
      selected: selected?.day == day.day,
      onTap: () => onSelected(day.day),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.level,
    required this.future,
    required this.selected,
    required this.onTap,
  });

  final DaySpend day;
  final int level;
  final bool future;
  final bool selected;
  final VoidCallback onTap;

  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    final fill = future
        ? context.colors.surface
        : context.colors.heatRamp[level];
    final textColor = level == 4
        ? context.colors.textOnNavy
        : (future ? context.colors.textSecondary : context.colors.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      label: future
          ? '${formatPickerDate(day.day)}, upcoming'
          : '${formatPickerDate(day.day)}: spent ${formatZmw(day.amount)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: future ? null : onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.enter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: selected
                    ? context.colors.navy
                    : (future ? context.colors.border : Colors.transparent),
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              '${day.day.day}',
              style: context.text.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.selected});

  final DaySpend? selected;

  @override
  Widget build(BuildContext context) {
    final day = selected;
    return Semantics(
      liveRegion: true,
      child: FadeSwitcher(
        alignment: Alignment.centerLeft,
        duration: AppMotion.short,
        child: day == null
            ? Text(
                'Tap a day to see what you spent.',
                key: ValueKey('hint'),
                style: context.text.caption,
              )
            : Text.rich(
                key: ValueKey(day.day),
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatZmw(day.amount),
                      style: context.text.listAmount,
                    ),
                    TextSpan(
                      text: '  ${formatPickerDate(day.day)}',
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Less', style: context.text.caption),
          const SizedBox(width: Dimens.gapS - 2),
          for (final color in context.colors.heatRamp) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Dimens.dataEndRadius),
              ),
            ),
            const SizedBox(width: 3),
          ],
          const SizedBox(width: 3),
          Text('More', style: context.text.caption),
        ],
      ),
    );
  }
}
