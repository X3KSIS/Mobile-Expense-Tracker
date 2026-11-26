import 'package:flutter/material.dart';

import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/transaction_row.dart';
import '../view_models/activity_view_model.dart';

/// A day heading with the day's net, then its transactions in a card.
class ActivityDaySection extends StatelessWidget {
  const ActivityDaySection({
    super.key,
    required this.day,
    required this.onTransactionTap,
    this.now,
  });

  final ActivityDay day;
  final ValueChanged<Transaction> onTransactionTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final net = day.net;
    final netLabel = net >= 0
        ? formatZmwSigned(net, isIncome: true)
        : formatZmwSigned(net, isIncome: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.gapXs),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    formatDayHeading(day.day, now: now).toUpperCase(),
                    style: context.text.overline,
                  ),
                ),
              ),
              Text(
                netLabel,
                style: context.text.caption.copyWith(
                  color: net > 0
                      ? context.colors.success
                      : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        ListCard(
          children: [
            for (final transaction in day.transactions)
              TransactionRow(
                transaction: transaction,
                now: now,
                onTap: () => onTransactionTap(transaction),
              ),
          ],
        ),
      ],
    );
  }
}
