/// How often a bill comes round.
enum BillCadence {
  weekly,
  monthly,
  yearly;

  /// The due date after [due]. Monthly and yearly bills keep their day
  /// ([anchorDay]), moving to the month's last day when it is shorter, so
  /// rent due on the 31st stays on the 31st (or the 30th, or the 28th).
  DateTime next(DateTime due, int anchorDay) => switch (this) {
    weekly => DateTime(due.year, due.month, due.day + 7),
    monthly => _onDay(due.year, due.month + 1, anchorDay),
    yearly => _onDay(due.year + 1, due.month, anchorDay),
  };

  static DateTime _onDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }
}

/// Where a bill stands today.
enum BillStatus {
  /// The due date has passed without it being marked paid.
  overdue,

  /// Due today.
  dueToday,

  /// Due within [Bill.dueSoonDays] days.
  dueSoon,

  /// Due later.
  upcoming,
}

/// A payment that comes round regularly (rent, DStv, school fees), set up
/// by the user so the app can remind them and mark it paid.
class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.walletId,
    required this.cadence,
    required this.nextDue,
    required this.anchorDay,
  });

  /// Bills due within this many days count as due soon, and the first
  /// reminder comes this many days before.
  static const int dueSoonDays = 7;

  final String id;
  final String name;
  final double amount;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final String walletId;
  final BillCadence cadence;

  /// The next date it is due (midnight).
  final DateTime nextDue;

  /// The day of the month it falls on, for monthly and yearly bills.
  final int anchorDay;

  /// Days from [now] to [nextDue]: 0 today, negative once overdue.
  int daysUntil(DateTime now) => DateTime.utc(
    nextDue.year,
    nextDue.month,
    nextDue.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  BillStatus status(DateTime now) {
    final days = daysUntil(now);
    if (days < 0) return BillStatus.overdue;
    if (days == 0) return BillStatus.dueToday;
    if (days <= dueSoonDays) return BillStatus.dueSoon;
    return BillStatus.upcoming;
  }

  /// This bill moved on to its next due date, after paying.
  Bill advanced() => copyWith(nextDue: cadence.next(nextDue, anchorDay));

  /// What this bill costs in an average month.
  double get monthlyCost => switch (cadence) {
    BillCadence.weekly => amount * 52 / 12,
    BillCadence.monthly => amount,
    BillCadence.yearly => amount / 12,
  };

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
    String? walletId,
    BillCadence? cadence,
    DateTime? nextDue,
    int? anchorDay,
  }) => Bill(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    categoryName: categoryName ?? this.categoryName,
    categoryIcon: categoryIcon ?? this.categoryIcon,
    categoryColor: categoryColor ?? this.categoryColor,
    walletId: walletId ?? this.walletId,
    cadence: cadence ?? this.cadence,
    nextDue: nextDue ?? this.nextDue,
    anchorDay: anchorDay ?? this.anchorDay,
  );

  @override
  bool operator ==(Object other) =>
      other is Bill &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.categoryName == categoryName &&
      other.walletId == walletId &&
      other.cadence == cadence &&
      other.nextDue == nextDue &&
      other.anchorDay == anchorDay;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    categoryName,
    walletId,
    cadence,
    nextDue,
    anchorDay,
  );
}

/// When to remind about bills: [Bill.dueSoonDays] days before, 3 days
/// before and on the day, then every morning while overdue, all at the
/// user's bill reminder time.
abstract final class BillReminders {
  /// Days before the due date with a reminder.
  static const List<int> daysBefore = [Bill.dueSoonDays, 3, 0];

  /// Mornings of overdue reminders scheduled ahead (they are rescheduled
  /// whenever the app opens, so this only matters if it stays closed).
  static const int overdueDays = 14;

  /// The reminders still to come for [bill] after [now], at [minutes]
  /// after midnight, oldest first. Each says how many days are left
  /// (negative once overdue).
  static List<({DateTime at, int daysLeft})> times(
    Bill bill,
    DateTime now,
    int minutes,
  ) {
    DateTime at(DateTime day) =>
        DateTime(day.year, day.month, day.day, 0, minutes);
    final due = bill.nextDue;
    final found = <({DateTime at, int daysLeft})>[
      for (final days in daysBefore)
        (at: at(DateTime(due.year, due.month, due.day - days)), daysLeft: days),
    ];
    // Overdue: every morning from the day after it was due.
    final today = DateTime(now.year, now.month, now.day);
    final firstLate = DateTime(due.year, due.month, due.day + 1);
    final start = today.isAfter(firstLate) ? today : firstLate;
    for (var i = 0; i < overdueDays; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      found.add((
        at: at(day),
        daysLeft: -DateTime.utc(
          day.year,
          day.month,
          day.day,
        ).difference(DateTime.utc(due.year, due.month, due.day)).inDays,
      ));
    }
    return [
      for (final r in found)
        if (r.at.isAfter(now)) r,
    ];
  }
}
