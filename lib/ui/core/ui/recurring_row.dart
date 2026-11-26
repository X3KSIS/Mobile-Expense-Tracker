import 'package:flutter/material.dart';

import '../../../domain/models/recurring_payment.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';
import 'category_icon.dart';
import 'category_tile.dart';
import 'status_badge.dart';

/// "Monthly", "Weekly" or "Every 2 weeks".
String cadenceLabel(Cadence cadence) => switch (cadence) {
  Cadence.weekly => 'Weekly',
  Cadence.fortnightly => 'Every 2 weeks',
  Cadence.monthly => 'Monthly',
};

/// One repeat payment: icon, name, rhythm and next date, amount, and a
/// badge when it is due soon or late.
class RecurringRow extends StatelessWidget {
  const RecurringRow({super.key, required this.payment, required this.now});

  final RecurringPayment payment;

  /// Today, for "due in 3 days".
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final when = p.status == RecurringStatus.late
        ? 'expected ${formatDayMonth(p.nextDue)}'
        : 'next ${formatDayMonth(p.nextDue)}';
    final badge = _badge();
    return MergeSemantics(
      child: Row(
        children: [
          IconTile(icon: CategoryIcons.resolve(p.categoryIcon)),
          const SizedBox(width: Dimens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: context.text.listTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    cadenceLabel(p.cadence),
                    when,
                    if (!p.fixedAmount) 'amount varies',
                    if (p.cadence != Cadence.monthly)
                      '${formatZmw(p.monthlyCost)} a month',
                  ].join(' · '),
                  style: context.text.caption,
                ),
                if (badge != null) ...[
                  const SizedBox(height: Dimens.gapXs + 2),
                  StatusBadge(tone: badge.$1, label: badge.$2),
                ],
              ],
            ),
          ),
          const SizedBox(width: Dimens.gapM),
          Text(formatZmw(p.amount), style: context.text.listAmount),
        ],
      ),
    );
  }

  (StatusTone, String)? _badge() {
    final today = DateTime(now.year, now.month, now.day);
    final days = payment.nextDue.difference(today).inHours ~/ 24;
    return switch (payment.status) {
      RecurringStatus.upcoming => null,
      RecurringStatus.late => (StatusTone.neutral, 'Not recorded yet'),
      RecurringStatus.dueSoon => (
        StatusTone.warning,
        days <= 0
            ? 'Due today'
            : days == 1
            ? 'Due tomorrow'
            : 'Due in $days days',
      ),
    };
  }
}
