import 'package:flutter/material.dart';

import '../../../domain/models/budget_alert.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/mesh_gradient_box.dart';

/// Navy mesh card warning about the budget closest to its limit.
class BudgetAlertCard extends StatelessWidget {
  const BudgetAlertCard({
    super.key,
    required this.alert,
    required this.onViewBudget,
  });

  final BudgetAlert alert;
  final VoidCallback onViewBudget;

  String get _message => alert.isOverLimit
      ? '${alert.categoryName} is over its limit.'
      : '${alert.categoryName} is almost at its limit.';

  @override
  Widget build(BuildContext context) {
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      padding: const EdgeInsets.all(Dimens.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: _AlertText(message: _message, onViewBudget: onViewBudget),
          ),
          const SizedBox(width: Dimens.gapL),
          _AlertFigures(alert: alert),
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
          style: context.text.overline.copyWith(
            color: context.colors.textOnNavyMuted,
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        Text(message, style: context.text.cardTitleOnNavy),
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
        Text('${alert.percentRounded}%', style: context.text.percentLarge),
        const SizedBox(height: Dimens.gapXs),
        Text(
          '$currencyCode ${formatWhole(alert.remaining)} LEFT',
          style: context.text.overline.copyWith(
            color: context.colors.textOnNavyMuted,
          ),
        ),
      ],
    );
  }
}
