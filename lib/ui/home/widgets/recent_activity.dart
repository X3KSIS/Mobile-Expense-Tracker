import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import 'transaction_row.dart';

/// "Recent activity" header with "See all", then the transaction list.
class RecentActivity extends StatelessWidget {
  const RecentActivity({
    super.key,
    required this.transactions,
    required this.onSeeAll,
  });

  final List<Transaction> transactions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent activity', style: textTheme.titleMedium),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: Dimens.gapS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Dimens.radiusList),
            border: Border.all(color: AppColors.border),
          ),
          child: transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Dimens.cardPadding),
                  child: Text(
                    'No transactions yet. Tap + to add your first one.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < transactions.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          indent:
                              Dimens.gapL + Dimens.iconTileSize + Dimens.gapM,
                          endIndent: Dimens.gapL,
                        ),
                      TransactionRow(transaction: transactions[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
