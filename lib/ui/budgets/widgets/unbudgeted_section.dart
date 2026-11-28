import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/list_card.dart';
import '../view_models/budgets_view_model.dart';

/// Where money goes without a limit: what was spent outside budgets this
/// cycle, then the biggest such categories, each with a one-tap budget
/// at a suggested amount.
class UnbudgetedSection extends StatelessWidget {
  const UnbudgetedSection({
    super.key,
    required this.total,
    required this.suggestions,
    required this.onSetBudget,
  });

  /// Spent this cycle on categories without a budget.
  final double total;
  final List<BudgetSuggestion> suggestions;
  final ValueChanged<BudgetSuggestion> onSetBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Not budgeted yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimens.gapXs),
        Text(
          '${formatZmw(total)} spent this cycle without a limit',
          style: context.text.label,
        ),
        const SizedBox(height: Dimens.gapM),
        ListCard(
          children: [
            for (final s in suggestions)
              _SuggestionRow(suggestion: s, onTap: () => onSetBudget(s)),
          ],
        ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final BudgetSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = suggestion.category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gapL,
        Dimens.gapM,
        Dimens.gapS,
        Dimens.gapM,
      ),
      child: Row(
        children: [
          CategoryTile(icon: category.icon),
          const SizedBox(width: Dimens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: context.text.listTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.spent > 0
                      ? '${formatZmw(suggestion.spent)} spent this cycle'
                      : 'Nothing yet this cycle',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label:
                'Set a ${category.name} budget of '
                '${formatZmw(suggestion.suggested)}',
            excludeSemantics: true,
            child: TextButton(
              onPressed: onTap,
              child: Text('Set ${formatWhole(suggestion.suggested)}'),
            ),
          ),
        ],
      ),
    );
  }
}
