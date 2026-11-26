import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/progress_bar.dart';
import '../../core/ui/mesh_gradient_box.dart';

/// Navy card with the month's total spent against all budgets.
class BudgetsSummaryCard extends StatelessWidget {
  const BudgetsSummaryCard({
    super.key,
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.percentUsed,
    required this.overCount,
  });

  final double spent;
  final double limit;
  final double remaining;
  final double percentUsed;
  final int overCount;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = context.text.body.copyWith(
      color: context.colors.textOnNavyMuted,
    );
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
            'SPENT THIS MONTH',
            style: context.text.overline.copyWith(
              color: context.colors.textOnNavyMuted,
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
                      color: context.colors.textOnNavyMuted,
                    ),
                  ),
                  TextSpan(
                    text: money.whole,
                    style: context.text.amountLarge.copyWith(
                      color: context.colors.accent,
                    ),
                  ),
                  TextSpan(
                    text: money.decimals,
                    style: context.text.amountDecimals.copyWith(
                      color: context.colors.textOnNavyMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.gapXs),
          Text('of ${formatZmw(limit)} budgeted', style: mutedStyle),
          const SizedBox(height: Dimens.gapL),
          ProgressBar(
            value: percentUsed,
            trackColor: context.colors.navyTrack,
            semanticLabel: 'Total budget used',
          ),
          const SizedBox(height: Dimens.gapM),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatZmw(remaining)} left',
                  style: context.text.listTitle.copyWith(
                    color: context.colors.textOnNavy,
                  ),
                ),
              ),
              if (overCount > 0)
                Text(
                  '$overCount over limit',
                  style: context.text.caption.copyWith(
                    color: context.colors.textOnNavyMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
