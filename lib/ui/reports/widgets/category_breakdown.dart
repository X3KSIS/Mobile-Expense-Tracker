import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/pressable.dart';
import '../../core/ui/progress_bar.dart';
import '../view_models/reports_view_model.dart';

/// Ranked horizontal bars of the month's spending by category, largest
/// first, in one hue. The category tile carries identity; the bar carries
/// magnitude relative to the largest category. Tapping a category opens
/// its trend.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<CategorySpend> categories;
  final ValueChanged<CategorySpend> onSelected;

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
          if (i > 0) const SizedBox(height: Dimens.gapS),
          _CategoryBar(
            category: categories[i],
            fraction: largest == 0 ? 0 : categories[i].amount / largest,
            onTap: () => onSelected(categories[i]),
          ),
        ],
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.fraction,
    required this.onTap,
  });

  final CategorySpend category;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (category.share * 100).round();
    return Semantics(
      button: true,
      label:
          '${category.name}: ${formatZmw(category.amount)}, $percent% of '
          'spending. Opens its trend',
      excludeSemantics: true,
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.gapXs),
            child: _barContent(context, percent),
          ),
        ),
      ),
    );
  }

  Widget _barContent(BuildContext context, int percent) {
    return Row(
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
        const SizedBox(width: Dimens.gapXs),
        Icon(
          Icons.chevron_right_rounded,
          size: Dimens.iconSizeSmall,
          color: context.colors.textSecondary,
        ),
      ],
    );
  }
}
