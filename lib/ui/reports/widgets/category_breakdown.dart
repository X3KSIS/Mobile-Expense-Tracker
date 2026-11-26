import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/progress_bar.dart';
import '../view_models/reports_view_model.dart';

/// Ranked horizontal bars of the month's spending by category, largest
/// first, in one hue. The category tile carries identity; the bar carries
/// magnitude relative to the largest category.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key, required this.categories});

  final List<CategorySpend> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'No spending this month.',
        style: context.text.body.copyWith(color: context.colors.textSecondary),
      );
    }
    final largest = categories.first.amount;
    return Column(
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(height: Dimens.gapL),
          _CategoryBar(
            category: categories[i],
            fraction: largest == 0 ? 0 : categories[i].amount / largest,
          ),
        ],
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.fraction});

  final CategorySpend category;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final percent = (category.share * 100).round();
    return Semantics(
      label:
          '${category.name}: ${formatZmw(category.amount)}, $percent% of '
          'spending',
      excludeSemantics: true,
      child: Row(
        children: [
          CategoryTile(icon: category.icon),
          const SizedBox(width: Dimens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: context.text.listTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatZmw(category.amount),
                      style: context.text.listAmount,
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.gapS - 2),
                Row(
                  children: [
                    Expanded(child: ProgressBar(value: fraction)),
                    const SizedBox(width: Dimens.gapS),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$percent%',
                        style: context.text.caption,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
