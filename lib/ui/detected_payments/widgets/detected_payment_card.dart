import 'package:flutter/material.dart';

import '../../../domain/models/detected_payment.dart';
import '../../../domain/models/money_message.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/status_badge.dart';
import '../../core/ui/wallet_tile.dart';

/// One detected payment: who, which service, when, the amount, and Add /
/// Dismiss.
class DetectedPaymentCard extends StatelessWidget {
  const DetectedPaymentCard({
    super.key,
    required this.payment,
    required this.onAdd,
    required this.onDismiss,
  });

  final DetectedPayment payment;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final m = payment.message;
    final withdrawal = m.kind == MoneyMessageKind.withdrawal;
    final provider = m.provider;
    final fee = m.fee;
    final details = [
      ?provider,
      formatActivityTime(payment.receivedAt),
      if (fee != null) 'Charge ${formatZmw(fee)}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(Dimens.gapL),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusList),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              WalletIconTile(kind: m.providerKind ?? WalletKind.mobileMoney),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.counterparty ?? provider ?? 'Payment',
                      style: context.text.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: context.text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimens.gapM),
              Text(
                withdrawal
                    ? formatZmw(m.amount)
                    : formatZmwSigned(m.amount, isIncome: m.isIncome),
                style: context.text.listAmount.copyWith(
                  color: m.isIncome ? colors.success : null,
                ),
              ),
            ],
          ),
          if (withdrawal) ...[
            const SizedBox(height: Dimens.gapM),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                tone: StatusTone.warning,
                label: 'Cash withdrawal: record it as Move money',
              ),
            ),
          ],
          const SizedBox(height: Dimens.gapM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: Text(withdrawal ? 'Move money' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
