import 'package:flutter/material.dart';

import '../../../domain/models/bill.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/status_badge.dart';

/// "Monthly", "Weekly" or "Yearly".
String cadenceName(BillCadence cadence) => switch (cadence) {
  BillCadence.weekly => 'Weekly',
  BillCadence.monthly => 'Monthly',
  BillCadence.yearly => 'Yearly',
};

/// When [bill] is due, in words: "3 days overdue", "Due today", "Due
/// tomorrow", "Due in 5 days", "Due 12 Jan".
String describeDue(Bill bill, DateTime now) {
  final days = bill.daysUntil(now);
  return switch (days) {
    < 0 => '${-days} day${days == -1 ? '' : 's'} overdue',
    0 => 'Due today',
    1 => 'Due tomorrow',
    <= Bill.dueSoonDays => 'Due in $days days',
    _ => 'Due ${formatDayMonth(bill.nextDue)}',
  };
}

/// How urgent [status] is, for its status mark.
StatusTone? billTone(BillStatus status) => switch (status) {
  BillStatus.overdue => StatusTone.danger,
  BillStatus.dueToday || BillStatus.dueSoon => StatusTone.warning,
  BillStatus.upcoming => null,
};

/// One bill: icon, name, when it's due and how often, and the amount.
class BillRow extends StatelessWidget {
  const BillRow({
    super.key,
    required this.bill,
    required this.now,
    required this.onTap,
  });

  final Bill bill;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = billTone(bill.status(now));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapL),
        child: MergeSemantics(
          child: Row(
            children: [
              IconTile(icon: CategoryIcons.resolve(bill.categoryIcon)),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: context.text.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (tone != null) ...[
                          StatusMark(tone: tone, size: 12),
                          const SizedBox(width: Dimens.gapXs + 2),
                        ],
                        Flexible(
                          child: Text(
                            describeDue(bill, now),
                            style: context.text.caption.copyWith(
                              color: tone == null
                                  ? colors.textSecondary
                                  : tone.strong(colors),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimens.gapS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatZmw(bill.amount), style: context.text.listAmount),
                  const SizedBox(height: 2),
                  Text(cadenceName(bill.cadence), style: context.text.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
