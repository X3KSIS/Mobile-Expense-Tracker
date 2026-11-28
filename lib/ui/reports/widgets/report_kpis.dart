import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../view_models/reports_view_model.dart';

/// The month's money in one card: what was spent first and largest, then
/// income and net side by side in equal columns. Each figure shows its
/// change from the previous month.
class ReportKpis extends StatelessWidget {
  const ReportKpis({super.key, required this.current, required this.previous});

  final MonthTotals current;
  final MonthTotals previous;

  @override
  Widget build(BuildContext context) {
    final vs = formatMonthShort(previous.month);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusList),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimens.cardPadding),
            child: _Figure(
              label: 'SPENT',
              value: current.expenses,
              previous: previous.expenses,
              upIsGood: false,
              vs: vs,
              large: true,
            ),
          ),
          const Divider(height: 1),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimens.gapL),
                    child: _Figure(
                      label: 'INCOME',
                      value: current.income,
                      previous: previous.income,
                      upIsGood: true,
                      vs: vs,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimens.gapL),
                    child: _Figure(
                      label: 'NET',
                      value: current.net,
                      previous: previous.net,
                      upIsGood: true,
                      vs: vs,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label, amount and change: one figure of the card.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.previous,
    required this.upIsGood,
    required this.vs,
    this.large = false,
  });

  final String label;
  final double value;
  final double previous;
  final bool upIsGood;
  final String vs;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.overline),
          const SizedBox(height: Dimens.gapXs),
          AnimatedNumber(
            value: value,
            builder: (context, shown) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatZmw(shown),
                style: large
                    ? context.text.amountMedium
                    : context.text.statValue,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: Dimens.gapXs),
          _Delta(value: value, previous: previous, upIsGood: upIsGood, vs: vs),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({
    required this.value,
    required this.previous,
    required this.upIsGood,
    required this.vs,
  });

  final double value;
  final double previous;
  final bool upIsGood;
  final String vs;

  @override
  Widget build(BuildContext context) {
    final change = value - previous;
    if (previous == 0 || change == 0) {
      return Text(
        previous == 0 ? 'No data for $vs' : 'Same as $vs',
        style: context.text.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final up = change > 0;
    final good = up == upIsGood;
    final percent = (change.abs() / previous.abs() * 100).round();
    final color = good ? context.colors.success : context.colors.accentText;
    return Row(
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: Dimens.iconSizeSmall - 4,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${up ? 'Up' : 'Down'} $percent% vs $vs',
            style: context.text.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
