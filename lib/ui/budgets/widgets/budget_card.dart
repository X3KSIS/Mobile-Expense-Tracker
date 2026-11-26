import 'package:flutter/material.dart';

import '../../../domain/models/budget_progress.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/progress_bar.dart';

/// One budget: category, amount spent of the limit, a progress bar and how
/// much is left (or over).
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.progress, required this.onTap});

  final BudgetProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final budget = progress.budget;
    final warn = progress.needsAttention;
    final radius = BorderRadius.circular(Dimens.radiusList);
    final status = progress.isOverLimit
        ? '${formatZmw(progress.overBy)} over'
        : '${formatZmw(progress.remaining)} left';
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(Dimens.gapL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CategoryTile(
                    icon: budget.categoryIcon,
                    color: budget.categoryColor,
                  ),
                  const SizedBox(width: Dimens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName,
                          style: context.text.listTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatZmw(progress.spent)} of '
                          '${formatZmw(budget.limit)}',
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progress.percentRounded}%',
                    style: context.text.statValue.copyWith(
                      color: warn
                          ? context.colors.accentText
                          : context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.gapM),
              ProgressBar(
                value: progress.percentUsed,
                color: warn
                    ? context.colors.accentStrong
                    : context.colors.accent,
                semanticLabel: '${budget.categoryName} budget used',
              ),
              const SizedBox(height: Dimens.gapS),
              Text(
                status,
                style: context.text.caption.copyWith(
                  color: progress.isOverLimit
                      ? context.colors.accentText
                      : context.colors.textSecondary,
                  fontWeight: progress.isOverLimit
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
