/// The stretch of days from one payday to the day before the next.
///
/// With payday 25, the cycle containing 26 November runs from 25 November
/// up to (not including) 25 December. Payday 1 gives calendar months.
class PayCycle {
  const PayCycle({required this.start, required this.end});

  /// Paydays run 1–28 so every month has one.
  static const int maxPayday = 28;

  /// Midnight on the payday that starts the cycle.
  final DateTime start;

  /// Midnight on the next payday (exclusive).
  final DateTime end;

  /// The cycle containing [date] when pay arrives on [payday] each month.
  factory PayCycle.containing(DateTime date, int payday) {
    final day = payday.clamp(1, maxPayday);
    final start = date.day >= day
        ? DateTime(date.year, date.month, day)
        : DateTime(date.year, date.month - 1, day);
    return PayCycle(
      start: start,
      end: DateTime(start.year, start.month + 1, day),
    );
  }

  /// True when the cycle is a plain calendar month (payday 1).
  bool get isCalendarMonth => start.day == 1;

  /// Number of days in the cycle.
  int get lengthInDays => _days(start, end);

  /// Days from [now] up to the next payday, counting today.
  int daysLeft(DateTime now) => _days(_midnight(now), end).clamp(1, 366);

  /// Days since the cycle started, counting today.
  int daysElapsed(DateTime now) =>
      (_days(start, _midnight(now)) + 1).clamp(1, lengthInDays);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar days between two dates, safe across daylight saving.
  static int _days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  @override
  bool operator ==(Object other) =>
      other is PayCycle && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PayCycle($start to $end)';
}
