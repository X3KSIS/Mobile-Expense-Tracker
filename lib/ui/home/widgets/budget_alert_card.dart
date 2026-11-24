import 'package:flutter/material.dart';

import '../../../domain/models/budget_alert.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// Navy card warning about the budget closest to its limit.
class BudgetAlertCard extends StatelessWidget {
  const BudgetAlertCard({
    super.key,
    required this.alert,
    required this.onViewBudget,
  });

  final BudgetAlert alert;
  final VoidCallback onViewBudget;

  static const double _circleSize = 160;

  String get _message => alert.isOverLimit
      ? '${alert.categoryName} is over its limit.'
      : '${alert.categoryName} is almost at its limit.';

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -_circleSize / 3,
            right: -_circleSize / 4,
            child: ExcludeSemantics(
              child: Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(
                    alpha: AppColors.softTintAlpha,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimens.cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: _AlertText(
                    message: _message,
                    onViewBudget: onViewBudget,
                  ),
                ),
                const SizedBox(width: Dimens.gapL),
                _AlertFigures(alert: alert),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertText extends StatelessWidget {
  const _AlertText({required this.message, required this.onViewBudget});

  final String message;
  final VoidCallback onViewBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUDGET ALERT',
          style: AppTypography.overline.copyWith(
            color: AppColors.textOnNavyMuted,
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        Text(message, style: AppTypography.cardTitleOnNavy),
        const SizedBox(height: Dimens.gapL),
        FilledButton(onPressed: onViewBudget, child: const Text('View budget')),
      ],
    );
  }
}

class _AlertFigures extends StatelessWidget {
  const _AlertFigures({required this.alert});

  final BudgetAlert alert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${alert.percentRounded}%', style: AppTypography.percentLarge),
        const SizedBox(height: Dimens.gapXs),
        Text(
          '$currencyCode ${formatWhole(alert.remaining)} LEFT',
          style: AppTypography.overline.copyWith(
            color: AppColors.textOnNavyMuted,
          ),
        ),
      ],
    );
  }
}
