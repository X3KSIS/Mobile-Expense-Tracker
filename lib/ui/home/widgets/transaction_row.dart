import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';

/// Icon tile, title, "time · category" and the signed amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.transaction, this.now});

  final Transaction transaction;

  /// Reference time for relative labels; defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = Color(transaction.categoryColor);
    final subtitle =
        '${formatActivityTime(transaction.date, now: now)} · ${transaction.categoryName}';
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.gapL,
          vertical: Dimens.gapM,
        ),
        child: Row(
          children: [
            Container(
              width: Dimens.iconTileSize,
              height: Dimens.iconTileSize,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: AppColors.softTintAlpha),
                borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
              ),
              child: Icon(
                CategoryIcons.resolve(transaction.categoryIcon),
                size: Dimens.iconSize,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Text(
              formatZmwSigned(
                transaction.amount,
                isIncome: transaction.isIncome,
              ),
              style: AppTypography.listAmount.copyWith(
                color: transaction.isIncome
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
