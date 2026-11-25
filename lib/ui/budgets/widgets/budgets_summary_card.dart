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
    final mutedStyle = AppTypography.body.copyWith(
      color: AppColors.textOnNavyMuted,
    );
    final money = splitMoney(spent);
    return MeshGradientBox(
      mesh: AppGradients.navyMesh,
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: AppShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT THIS MONTH',
            style: AppTypography.overline.copyWith(
              color: AppColors.textOnNavyMuted,
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
                    style: AppTypography.amountPrefix.copyWith(
                      color: AppColors.textOnNavyMuted,
                    ),
                  ),
                  TextSpan(
                    text: money.whole,
                    style: AppTypography.amountLarge.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  TextSpan(
                    text: money.decimals,
                    style: AppTypography.amountDecimals.copyWith(
                      color: AppColors.textOnNavyMuted,
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
            trackColor: AppColors.navyTrack,
            semanticLabel: 'Total budget used',
          ),
          const SizedBox(height: Dimens.gapM),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatZmw(remaining)} left',
                  style: AppTypography.listTitle.copyWith(
                    color: AppColors.textOnNavy,
                  ),
                ),
              ),
              if (overCount > 0)
                Text(
                  '$overCount over limit',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textOnNavyMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
