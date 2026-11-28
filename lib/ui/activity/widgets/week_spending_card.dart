import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';

/// What was spent over the last week: the total against the week before,
/// one column per day (tap a day to read its amount; today is picked at
/// first) and what came in.
class WeekSpendingCard extends StatefulWidget {
  const WeekSpendingCard({
    super.key,
    required this.days,
    required this.spentByDay,
    required this.spentLastWeek,
    required this.received,
  });

  /// Oldest first, ending today.
  final List<DateTime> days;
  final List<double> spentByDay;
  final double spentLastWeek;
  final double received;

  @override
  State<WeekSpendingCard> createState() => _WeekSpendingCardState();
}

class _WeekSpendingCardState extends State<WeekSpendingCard> {
  int? _picked;

  int get _selected => _picked ?? widget.days.length - 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = widget.spentByDay.fold(0.0, (sum, v) => sum + v);
    return Container(
      padding: const EdgeInsets.all(Dimens.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPENT THIS WEEK', style: context.text.overline),
          const SizedBox(height: Dimens.gapXs),
          AnimatedNumber(
            value: total,
            builder: (context, value) =>
                Text(formatZmw(value), style: context.text.amountMedium),
          ),
          const SizedBox(height: Dimens.gapXs),
          _Comparison(
            change: total - widget.spentLastWeek,
            hasLastWeek: widget.spentLastWeek > 0,
          ),
          const SizedBox(height: Dimens.gapL),
          _DayBars(
            days: widget.days,
            spentByDay: widget.spentByDay,
            selected: _selected,
            onSelected: (i) => setState(() => _picked = i),
          ),
          if (widget.received > 0) ...[
            const SizedBox(height: Dimens.gapM),
            const Divider(height: 1),
            const SizedBox(height: Dimens.gapM),
            Row(
              children: [
                Icon(
                  Icons.south_west_rounded,
                  size: Dimens.iconSizeSmall,
                  color: colors.success,
                ),
                const SizedBox(width: Dimens.gapS),
                Expanded(
                  child: Text('Money in this week', style: context.text.label),
                ),
                Text(
                  formatZmw(widget.received),
                  style: context.text.label.copyWith(color: colors.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.change, required this.hasLastWeek});

  final double change;
  final bool hasLastWeek;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = !hasLastWeek
        ? (Icons.insights_rounded, 'Nothing spent the week before')
        : change.abs() < 1
        ? (Icons.trending_flat_rounded, 'Same as the week before')
        : (
            change > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            '${formatZmw(change.abs())} ${change > 0 ? 'more' : 'less'} '
                'than the week before',
          );
    return Row(
      children: [
        Icon(
          icon,
          size: Dimens.iconSizeSmall,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: Dimens.gapS),
        Expanded(child: Text(text, style: context.text.label)),
      ],
    );
  }
}

/// Seven columns, one per day. The selected day is the coral mark and
/// its amount shows above the chart; the others are muted.
class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.days,
    required this.spentByDay,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final List<double> spentByDay;
  final int selected;
  final ValueChanged<int> onSelected;

  static const double _plot = 72;

  @override
  Widget build(BuildContext context) {
    final top = spentByDay.fold(0.0, math.max);
    final isToday = selected == days.length - 1;
    final day = days[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${isToday ? 'Today' : DateFormat('EEEE d MMM').format(day)} · '
          '${formatZmw(spentByDay[selected])}',
          style: context.text.caption.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: _DayColumn(
                  day: days[i],
                  amount: spentByDay[i],
                  height: top <= 0 ? 0 : _plot * spentByDay[i] / top,
                  selected: i == selected,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.amount,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final double amount;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${DateFormat('EEEE').format(day)}, spent ${formatZmw(amount)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusInput),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXs),
          child: Column(
            children: [
              SizedBox(
                height: _DayBars._plot,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.move,
                    width: Dimens.columnMaxWidth,
                    height: math.max(height, amount > 0 ? 2 : 0),
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.chartMuted,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Dimens.dataEndRadius),
                      ),
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: colors.border),
              const SizedBox(height: Dimens.gapXs),
              SizedBox(
                height: Dimens.minTouchTarget - Dimens.gapM,
                child: Center(
                  child: Text(
                    DateFormat('E').format(day).substring(0, 2),
                    style: context.text.caption.copyWith(
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
