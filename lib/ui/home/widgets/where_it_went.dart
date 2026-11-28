import 'package:flutter/material.dart';

import '../../../domain/models/budget_progress.dart';
import '../../../domain/models/cycle_spending.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/progress_bar.dart';
import '../../core/ui/status_badge.dart';

/// The categories most spent on this pay cycle: each one's share of the
/// spending and, when it has a budget, how much of it is used, with a
/// status mark once it nears or passes the limit.
class WhereItWent extends StatelessWidget {
  const WhereItWent({
    super.key,
    required this.categories,
    required this.total,
    required this.hideAmounts,
    required this.onSeeAll,
    required this.onCategoryTap,
    this.limit = 4,
  });

  final List<CategorySpend> categories;

  /// Everything spent this cycle, for each category's share.
  final double total;
  final bool hideAmounts;
  final VoidCallback onSeeAll;
  final ValueChanged<CategorySpend> onCategoryTap;

  /// How many categories to show.
  final int limit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Where it went',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See report')),
          ],
        ),
        const SizedBox(height: Dimens.gapS),
        ListCard(
          children: [
            for (final category in categories.take(limit))
              _CategoryRow(
                category: category,
                share: total <= 0 ? 0 : category.amount / total,
                hideAmounts: hideAmounts,
                onTap: () => onCategoryTap(category),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.share,
    required this.hideAmounts,
    required this.onTap,
  });

  final CategorySpend category;
  final double share;
  final bool hideAmounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (share * 100).round();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapL),
        child: MergeSemantics(
          child: Row(
            children: [
              IconTile(icon: CategoryIcons.resolve(category.icon)),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleLine(
                      name: category.name,
                      amount: hideAmounts
                          ? '$currencyCode ••••'
                          : formatZmw(category.amount),
                    ),
                    const SizedBox(height: Dimens.gapS),
                    ProgressBar(
                      value: share,
                      semanticLabel: '$percent% of your spending',
                    ),
                    const SizedBox(height: Dimens.gapS),
                    _Detail(budget: category.budget, percent: percent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleLine extends StatelessWidget {
  const _TitleLine({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: context.text.listTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Dimens.gapS),
        Text(amount, style: context.text.listAmount),
      ],
    );
  }
}

/// "32% of your spending", plus the budget when there is one, e.g.
/// "· 97% of budget" with a warning mark.
class _Detail extends StatelessWidget {
  const _Detail({required this.budget, required this.percent});

  final BudgetProgress? budget;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final budget = this.budget;
    final tone = switch (budget?.status) {
      BudgetStatus.overLimit => StatusTone.danger,
      BudgetStatus.nearLimit => StatusTone.warning,
      _ => null,
    };
    final budgetText = budget == null
        ? null
        : budget.isOverLimit
        ? 'over budget by ${formatZmw(budget.overBy)}'
        : '${budget.percentRounded}% of budget';
    return Row(
      children: [
        if (tone != null) ...[
          StatusMark(tone: tone, size: 12),
          const SizedBox(width: Dimens.gapXs + 2),
        ],
        Expanded(
          child: Text(
            ['$percent% of your spending', ?budgetText].join(' · '),
            style: context.text.caption.copyWith(
              color: tone == null
                  ? context.colors.textSecondary
                  : tone.strong(context.colors),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
