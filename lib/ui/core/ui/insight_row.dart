import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/spending_insight.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';
import 'category_icon.dart';
import 'category_tile.dart';
import 'status_badge.dart';

/// The words for a [SpendingInsight] about [month].
///
/// [monthToDate] is true while [month] is still running, when comparisons
/// are "by this point last month" rather than against the whole month.
({String title, String detail}) describeInsight(
  SpendingInsight insight, {
  required DateTime month,
  required bool monthToDate,
}) {
  final prevMonth = DateTime(month.year, month.month - 1);
  final then = monthToDate
      ? 'by this point last month'
      : 'in ${formatMonth(prevMonth)}';
  final now = monthToDate ? 'so far' : 'in ${formatMonth(month)}';
  final period = monthToDate ? 'this month' : 'in ${formatMonth(month)}';
  final previous = insight.previous ?? 0;
  final change = insight.change;
  final percent = change == null ? '' : '${(change.abs() * 100).round()}%';
  final label = insight.label ?? '';

  return switch (insight.kind) {
    InsightKind.pace => switch (insight.trend) {
      InsightTrend.up => (
        title: 'Spending is up $percent',
        detail:
            '${formatZmw(insight.amount)} $now, against '
            '${formatZmw(previous)} $then.',
      ),
      InsightTrend.down => (
        title: 'Spending is down $percent',
        detail:
            '${formatZmw(insight.amount)} $now, against '
            '${formatZmw(previous)} $then.',
      ),
      InsightTrend.steady => (
        title: 'Spending is steady',
        detail:
            'About the same as $then: ${formatZmw(insight.amount)} '
            'against ${formatZmw(previous)}.',
      ),
    },
    InsightKind.categoryUp => (
      title: previous <= 0 ? 'New this month: $label' : '$label up $percent',
      detail: previous <= 0
          ? '${formatZmw(insight.amount)} $now, and nothing $then.'
          : '${formatZmw(insight.amount)} $now, against '
                '${formatZmw(previous)} $then.',
    ),
    InsightKind.categoryDown =>
      insight.amount <= 0
          ? (
              title:
                  'No ${label.toLowerCase()} spending '
                  '${monthToDate ? 'yet' : 'in ${formatMonth(month)}'}',
              detail: 'Against ${formatZmw(previous)} $then. Well done.',
            )
          : (
              title: '$label down $percent',
              detail:
                  '${formatZmw(insight.amount)} $now, against '
                  '${formatZmw(previous)} $then. Well done.',
            ),
    InsightKind.risingStreak => (
      title: '$label up ${insight.count} months running',
      detail:
          'From ${formatZmw(previous)} to ${formatZmw(insight.amount)} a '
          'month. Worth a look.',
    ),
    InsightKind.topPlace => (
      title: '$label is your top place',
      detail:
          '${formatZmw(insight.amount)} over ${insight.count} visits '
          '$period.',
    ),
    InsightKind.smallSpends => (
      title: 'Small spends add up',
      detail:
          '${insight.count} purchases of '
          '${formatZmw(SpendingInsights.smallSpend)} or less came to '
          '${formatZmw(insight.amount)} $period.',
    ),
    InsightKind.busiestDay => (
      title: '${_weekday(label)}s cost you most',
      detail:
          'About ${formatZmw(insight.amount)} on an average '
          '${_weekday(label)}, against ${formatZmw(previous)} on other days.',
    ),
  };
}

/// "Saturday" for "6" (ISO weekday numbers, Monday is 1).
String _weekday(String isoDay) {
  final day = int.tryParse(isoDay) ?? 1;
  // 5 January 2026 was a Monday.
  return DateFormat.EEEE().format(DateTime(2026, 1, 4 + day));
}

IconData _icon(SpendingInsight insight) {
  final category = insight.icon;
  if (category != null) return CategoryIcons.resolve(category);
  return switch (insight.kind) {
    InsightKind.pace => Icons.speed_rounded,
    InsightKind.smallSpends => Icons.grain_rounded,
    InsightKind.busiestDay => Icons.calendar_today_outlined,
    InsightKind.topPlace => Icons.storefront_outlined,
    _ => Icons.insights_outlined,
  };
}

/// One insight: an icon, the headline, the detail and, for changes, an
/// up or down badge. Spending going up reads as a warning; going down as
/// good news.
class InsightRow extends StatelessWidget {
  const InsightRow({
    super.key,
    required this.insight,
    required this.month,
    required this.monthToDate,
  });

  final SpendingInsight insight;
  final DateTime month;
  final bool monthToDate;

  @override
  Widget build(BuildContext context) {
    final text = describeInsight(
      insight,
      month: month,
      monthToDate: monthToDate,
    );
    final badge = switch ((insight.kind, insight.trend)) {
      (InsightKind.topPlace || InsightKind.smallSpends, _) => null,
      (InsightKind.busiestDay, _) => null,
      (_, InsightTrend.up) => (StatusTone.warning, 'Up'),
      (_, InsightTrend.down) => (StatusTone.success, 'Down'),
      (_, InsightTrend.steady) => (StatusTone.neutral, 'Steady'),
    };
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: _icon(insight)),
          const SizedBox(width: Dimens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.title, style: context.text.listTitle),
                const SizedBox(height: 2),
                Text(text.detail, style: context.text.caption),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: Dimens.gapS),
            StatusBadge(tone: badge.$1, label: badge.$2),
          ],
        ],
      ),
    );
  }
}
