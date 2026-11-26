import 'package:flutter/material.dart';

import '../../../domain/models/spending_insight.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/insight_row.dart';

/// The month's spending insights, one per row, most worth acting on first.
class HabitList extends StatelessWidget {
  const HabitList({
    super.key,
    required this.insights,
    required this.month,
    required this.monthToDate,
  });

  final List<SpendingInsight> insights;
  final DateTime month;
  final bool monthToDate;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Text(
        'Not enough spending yet to spot habits. Keep recording and they '
        'will show up here.',
        style: context.text.caption,
      );
    }
    return Column(
      children: [
        for (final (i, insight) in insights.indexed) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Dimens.gapM),
              child: Divider(),
            ),
          InsightRow(insight: insight, month: month, monthToDate: monthToDate),
        ],
      ],
    );
  }
}
