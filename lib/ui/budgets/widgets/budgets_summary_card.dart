import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/mesh_gradient_box.dart';
import 'budget_bar.dart';

/// Navy card with what was spent against all budgets this cycle: the bar
/// with its "today" marker, what is left and what that allows per day
/// until payday, and how many budgets need attention.
class BudgetsSummaryCard extends StatelessWidget {
  const BudgetsSummaryCard({
    super.key,
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.percentUsed,
    required this.cycleFraction,
    required this.safePerDay,
    required this.daysLeft,
    required this.attentionCount,
  });

  final double spent;
  final double limit;
  final double remaining;
  final double percentUsed;
  final double cycleFraction;
  final double safePerDay;
  final int daysLeft;

  /// Budgets near or over their limit.
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = context.text.caption.copyWith(color: colors.textOnNavyMuted);
    final money = splitMoney(spent);
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: context.shadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT ON BUDGETS',
            style: context.text.overline.copyWith(
              color: colors.textOnNavyMuted,
            ),
          ),
          const SizedBox(height: Dimens.gapS),
          Semantics(
            label: 'Spent ${formatZmw(spent)} of ${formatZmw(limit)}',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$currencyCode ',
                    style: context.text.amountPrefix.copyWith(
                      color: colors.textOnNavyMuted,
                    ),
                  ),
                  TextSpan(
                    text: money.whole,
                    style: context.text.amountLarge.copyWith(
                      color: colors.accent,
                    ),
                  ),
                  TextSpan(
                    text: money.decimals,
                    style: context.text.amountDecimals.copyWith(
                      color: colors.textOnNavyMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'of ${formatZmw(limit)} budgeted',
            style: context.text.body.copyWith(color: colors.textOnNavyMuted),
          ),
          const SizedBox(height: Dimens.gapL),
          BudgetBar(
            value: percentUsed,
            planned: cycleFraction,
            trackColor: colors.navyTrack,
            markerColor: colors.textOnNavy,
            semanticLabel:
                '${(percentUsed * 100).round()}% of all budgets used, '
                '${(cycleFraction * 100).round()}% of the cycle gone',
          ),
          const SizedBox(height: Dimens.gapM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatZmw(remaining)} left',
                      style: context.text.listTitle.copyWith(
                        color: colors.textOnNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatZmw(safePerDay)} a day for '
                      '$daysLeft day${daysLeft == 1 ? '' : 's'}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              if (attentionCount > 0)
                Text(
                  '$attentionCount need${attentionCount == 1 ? 's' : ''} '
                  'a look',
                  style: muted,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
