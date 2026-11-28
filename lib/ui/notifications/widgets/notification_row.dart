import 'package:flutter/material.dart';

import '../../../domain/models/app_notification.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/status_badge.dart';

/// The words for [n]: a short title and a line of detail.
({String title, String body}) describeNotification(
  AppNotification n,
  DateTime now,
) => switch (n.kind) {
  NotificationKind.overBudget => (
    title: '${n.subject} is over budget',
    body:
        'Over by ${formatZmw(n.amount)} this pay cycle '
        '(${n.percent}% used).',
  ),
  NotificationKind.nearBudget => (
    title: '${n.subject} is at ${n.percent}% of its budget',
    body: 'Slow down to stay within it until payday.',
  ),
  NotificationKind.paymentLate => (
    title: '${n.subject} looks late',
    body:
        'Usually ${formatZmw(n.amount)}, expected '
        '${formatDayMonth(n.due!)}. Add it if you have paid.',
  ),
  NotificationKind.paymentDueSoon => (
    title: '${n.subject} is due ${_dueWhen(n.due!, now)}',
    body: 'Usually ${formatZmw(n.amount)}. Keep it aside.',
  ),
  NotificationKind.billOverdue => (
    title: '${n.subject} is overdue',
    body:
        '${formatZmw(n.amount)} was due ${formatDayMonth(n.due!)}. '
        'Mark it paid in Bills.',
  ),
  NotificationKind.billDue => (
    title: '${n.subject} is due ${_dueWhen(n.due!, now)}',
    body: '${formatZmw(n.amount)}. Mark it paid once done.',
  ),
  NotificationKind.paymentsToReview => (
    title: n.count == 1
        ? '1 payment to review'
        : '${n.count} payments to review',
    body: 'Read from your messages. Add them in a tap.',
  ),
};

String _dueWhen(DateTime due, DateTime now) {
  final days = dateOnly(due).difference(dateOnly(now)).inDays;
  return switch (days) {
    <= 0 => 'today',
    1 => 'tomorrow',
    _ => 'in $days days',
  };
}

/// How urgent [kind] is, shown with its status mark.
StatusTone notificationTone(NotificationKind kind) => switch (kind) {
  NotificationKind.overBudget ||
  NotificationKind.paymentLate ||
  NotificationKind.billOverdue => StatusTone.danger,
  NotificationKind.nearBudget ||
  NotificationKind.paymentDueSoon ||
  NotificationKind.billDue => StatusTone.warning,
  NotificationKind.paymentsToReview => StatusTone.neutral,
};

IconData _icon(NotificationKind kind) => switch (kind) {
  NotificationKind.overBudget ||
  NotificationKind.nearBudget => Icons.donut_large_rounded,
  NotificationKind.paymentLate ||
  NotificationKind.paymentDueSoon ||
  NotificationKind.billOverdue ||
  NotificationKind.billDue => Icons.event_repeat_rounded,
  NotificationKind.paymentsToReview => Icons.sms_outlined,
};

/// One notification: icon, status mark, title, detail and when.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final words = describeNotification(notification, now);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.gapL),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: _icon(notification.kind)),
              const SizedBox(width: Dimens.gapM),
              Expanded(child: _text(context, words)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context, ({String title, String body}) words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusMark(tone: notificationTone(notification.kind), size: 14),
            const SizedBox(width: Dimens.gapS),
            Expanded(child: Text(words.title, style: context.text.listTitle)),
          ],
        ),
        const SizedBox(height: Dimens.gapXs),
        Text(words.body, style: context.text.label),
        const SizedBox(height: Dimens.gapXs),
        Text(
          _capitalised(formatAgo(notification.at, now)),
          style: context.text.caption,
        ),
      ],
    );
  }

  static String _capitalised(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
