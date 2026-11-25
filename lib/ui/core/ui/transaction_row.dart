import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';
import 'category_tile.dart';

/// Icon tile, title, "time · category" and the signed amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.now,
    this.onTap,
  });

  final Transaction transaction;

  /// Opens the transaction's details. Null makes the row read-only.
  final VoidCallback? onTap;

  /// Reference time for relative labels; defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle =
        '${formatActivityTime(transaction.date, now: now)} · ${transaction.categoryName}';
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gapL,
            vertical: Dimens.gapM,
          ),
          child: Row(
            children: [
              CategoryTile(
                icon: transaction.categoryIcon,
                color: transaction.categoryColor,
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
      ),
    );
  }
}
