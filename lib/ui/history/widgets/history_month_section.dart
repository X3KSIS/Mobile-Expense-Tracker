import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../activity/widgets/activity_day_section.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/expandable_section.dart';
import '../view_models/history_view_model.dart';

/// A month heading with its money in and out, then its days. Folds away
/// when the filter leaves nothing in the month.
class HistoryMonthSection extends StatelessWidget {
  const HistoryMonthSection({
    super.key,
    required this.month,
    required this.viewModel,
    required this.onTransactionTap,
  });

  final HistoryMonth month;
  final HistoryViewModel viewModel;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return ExpandableSection(
      expanded: viewModel.hasVisible(month),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimens.gapS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonthHeading(
              month: month.month,
              income: viewModel.incomeIn(month),
              expenses: viewModel.expensesIn(month),
            ),
            const SizedBox(height: Dimens.gapM),
            for (final day in month.days)
              ActivityDaySection(
                key: ValueKey(day.day),
                day: day,
                isVisible: viewModel.isVisible,
                onTransactionTap: onTransactionTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final DateTime month;
  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.gapL,
        vertical: Dimens.gapM,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Dimens.radiusTile),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                formatMonthYear(month),
                style: context.text.sectionTitle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumber(
                value: income,
                builder: (context, v) => Text(
                  'In ${formatZmw(v)}',
                  style: context.text.caption.copyWith(color: colors.success),
                ),
              ),
              AnimatedNumber(
                value: expenses,
                builder: (context, v) =>
                    Text('Out ${formatZmw(v)}', style: context.text.caption),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
