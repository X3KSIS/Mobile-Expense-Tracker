import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/recurring_payment.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/recurring_row.dart';

/// The biggest repeat payments, with a link to all of them.
class RegularPaymentsSummary extends StatelessWidget {
  const RegularPaymentsSummary({
    super.key,
    required this.payments,
    required this.now,
    this.shown = 3,
  });

  final List<RecurringPayment> payments;
  final DateTime now;

  /// How many to list before "See all".
  final int shown;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Text(
        'Nothing paid on a regular rhythm yet. Rent, DStv or weekly fuel '
        'show up here once paid three times.',
        style: context.text.caption,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in payments.take(shown).indexed) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Dimens.gapM),
              child: Divider(),
            ),
          RecurringRow(payment: p, now: now),
        ],
        const SizedBox(height: Dimens.gapS),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push(Routes.recurring),
            child: Text(
              payments.length > shown
                  ? 'See all ${payments.length} regular payments'
                  : 'See regular payments',
            ),
          ),
        ),
      ],
    );
  }
}
