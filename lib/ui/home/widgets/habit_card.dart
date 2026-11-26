import 'package:flutter/material.dart';

import '../../../domain/models/spending_insight.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/insight_row.dart';

/// The spending habit most worth knowing about this month, with a link to
/// the rest in Reports.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.insight,
    required this.month,
    required this.onSeeAll,
  });

  final SpendingInsight insight;
  final DateTime month;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimens.cardPadding,
        Dimens.gapM,
        Dimens.gapS,
        Dimens.cardPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR SPENDING HABITS',
                  style: context.text.overline,
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: Dimens.gapXs),
          Padding(
            padding: const EdgeInsets.only(right: Dimens.gapM),
            child: FadeSwitcher(
              child: InsightRow(
                key: ValueKey((insight.kind, insight.label, insight.amount)),
                insight: insight,
                month: month,
                monthToDate: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
