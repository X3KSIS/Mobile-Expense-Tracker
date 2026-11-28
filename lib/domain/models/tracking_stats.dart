import 'transaction.dart';

/// How steadily the user records their money: the streak of days with
/// something recorded, how much was recorded this month, and for how many
/// months.
class TrackingStats {
  const TrackingStats({
    required this.streak,
    required this.thisMonth,
    required this.monthsTracked,
  });

  /// Days in a row, ending today, with at least one transaction. A day
  /// without one yet today doesn't break it: the streak then ends
  /// yesterday.
  final int streak;

  /// Transactions recorded in the current month.
  final int thisMonth;

  /// Months with at least one transaction.
  final int monthsTracked;

  static const TrackingStats empty = TrackingStats(
    streak: 0,
    thisMonth: 0,
    monthsTracked: 0,
  );

  static TrackingStats compute(List<Transaction> transactions, DateTime now) {
    final days = <DateTime>{};
    final months = <DateTime>{};
    var thisMonth = 0;
    for (final t in transactions) {
      if (t.date.isAfter(now)) continue;
      days.add(DateTime(t.date.year, t.date.month, t.date.day));
      months.add(DateTime(t.date.year, t.date.month));
      if (t.date.year == now.year && t.date.month == now.month) thisMonth++;
    }
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return TrackingStats(
      streak: streak,
      thisMonth: thisMonth,
      monthsTracked: months.length,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrackingStats &&
      other.streak == streak &&
      other.thisMonth == thisMonth &&
      other.monthsTracked == monthsTracked;

  @override
  int get hashCode => Object.hash(streak, thisMonth, monthsTracked);
}
