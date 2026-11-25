import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../view_models/reports_view_model.dart';

/// Income, expenses and net for the month, each with the change from the
/// previous month.
class ReportKpis extends StatelessWidget {
  const ReportKpis({super.key, required this.current, required this.previous});

  final MonthTotals current;
  final MonthTotals previous;

  @override
  Widget build(BuildContext context) {
    final vs = formatMonthShort(previous.month);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Income',
                value: current.income,
                previous: previous.income,
                upIsGood: true,
                vs: vs,
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: _KpiTile(
                label: 'Expenses',
                value: current.expenses,
                previous: previous.expenses,
                upIsGood: false,
                vs: vs,
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.gapM),
        _KpiTile(
          label: 'Net (income minus expenses)',
          value: current.net,
          previous: previous.net,
          upIsGood: true,
          vs: vs,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.previous,
    required this.upIsGood,
    required this.vs,
  });

  final String label;
  final double value;
  final double previous;
  final bool upIsGood;
  final String vs;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Dimens.gapL - 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimens.radiusTile),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: Dimens.gapXs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatZmw(value), style: AppTypography.statValue),
            ),
            const SizedBox(height: Dimens.gapXs),
            _Delta(
              value: value,
              previous: previous,
              upIsGood: upIsGood,
              vs: vs,
            ),
          ],
        ),
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
        style: AppTypography.caption,
      );
    }
    final up = change > 0;
    final good = up == upIsGood;
    final percent = (change.abs() / previous.abs() * 100).round();
    final color = good ? AppColors.success : AppColors.accentText;
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
            style: AppTypography.caption.copyWith(
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
