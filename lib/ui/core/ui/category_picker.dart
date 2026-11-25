import 'package:flutter/material.dart';

import '../../../domain/models/transaction_category.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'category_tile.dart';

/// Four-column grid of categories. The selected one gets a navy ring.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory> onSelected;

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - Dimens.gapS * (_columns - 1)) / _columns;
        return Wrap(
          spacing: Dimens.gapS,
          runSpacing: Dimens.gapM,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _CategoryOption(
                  category: category,
                  selected: category == selected,
                  onTap: () => onSelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusButton);
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.gapXs),
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.short,
                curve: AppMotion.enter,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimens.radiusTile),
                  border: Border.all(
                    color: selected ? AppColors.navy : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CategoryTile(
                  icon: category.icon,
                  color: category.color,
                  size: Dimens.quickActionSize - 4,
                ),
              ),
              const SizedBox(height: Dimens.gapXs + 2),
              AnimatedDefaultTextStyle(
                duration: AppMotion.short,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
