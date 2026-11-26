import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/transaction_row.dart';

/// "Recent activity" header with "See all", then the transaction list.
class RecentActivity extends StatelessWidget {
  const RecentActivity({
    super.key,
    required this.transactions,
    required this.onSeeAll,
    required this.onTransactionTap,
  });

  final List<Transaction> transactions;
  final VoidCallback onSeeAll;
  final ValueChanged<Transaction> onTransactionTap;

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
        if (transactions.isEmpty)
          ListCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimens.cardPadding),
                child: Text(
                  'No transactions yet. Tap + to add your first one.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        else
          ListCard(
            children: [
              for (final transaction in transactions)
                TransactionRow(
                  transaction: transaction,
                  onTap: () => onTransactionTap(transaction),
                ),
            ],
          ),
      ],
    );
  }
}
