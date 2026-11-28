import 'package:flutter_expensetracker/domain/models/bill.dart';
import 'package:flutter_test/flutter_test.dart';

Bill _bill({
  required DateTime due,
  BillCadence cadence = BillCadence.monthly,
  int? anchorDay,
}) => Bill(
  id: 'b',
  name: 'Rent',
  amount: 3500,
  categoryName: 'Housing',
  categoryIcon: 'housing',
  categoryColor: 0,
  walletId: 'w-cash',
  cadence: cadence,
  nextDue: due,
  anchorDay: anchorDay ?? due.day,
);

void main() {
  test('monthly bills keep their day, even after a short month', () {
    final jan31 = _bill(due: DateTime(2027, 1, 31));
    final feb = jan31.advanced();
    expect(feb.nextDue, DateTime(2027, 2, 28));
    expect(feb.advanced().nextDue, DateTime(2027, 3, 31));
  });

  test('weekly and yearly bills move on by a week and a year', () {
    expect(
      _bill(
        due: DateTime(2026, 12, 29),
        cadence: BillCadence.weekly,
      ).advanced().nextDue,
      DateTime(2027, 1, 5),
    );
    expect(
      _bill(
        due: DateTime(2028, 2, 29),
        cadence: BillCadence.yearly,
      ).advanced().nextDue,
      DateTime(2029, 2, 28),
    );
  });

  test('status follows the due date', () {
    final now = DateTime(2026, 11, 28, 15);
    expect(_bill(due: DateTime(2026, 11, 27)).status(now), BillStatus.overdue);
    expect(_bill(due: DateTime(2026, 11, 28)).status(now), BillStatus.dueToday);
    expect(_bill(due: DateTime(2026, 12, 5)).status(now), BillStatus.dueSoon);
    expect(_bill(due: DateTime(2026, 12, 6)).status(now), BillStatus.upcoming);
    expect(_bill(due: DateTime(2026, 11, 25)).daysUntil(now), -3);
  });

  test('monthly cost spreads weekly and yearly bills', () {
    expect(
      _bill(
        due: DateTime(2026, 12, 1),
        cadence: BillCadence.yearly,
      ).monthlyCost,
      closeTo(3500 / 12, 0.001),
    );
    expect(
      _bill(
        due: DateTime(2026, 12, 1),
        cadence: BillCadence.weekly,
      ).monthlyCost,
      closeTo(3500 * 52 / 12, 0.001),
    );
  });

  test('reminders: a week, 3 days, the day, then every morning', () {
    final bill = _bill(due: DateTime(2026, 12, 10));
    final times = BillReminders.times(bill, DateTime(2026, 12, 1, 6), 8 * 60);
    expect(times.take(4).map((r) => (r.at, r.daysLeft)), [
      (DateTime(2026, 12, 3, 8), 7),
      (DateTime(2026, 12, 7, 8), 3),
      (DateTime(2026, 12, 10, 8), 0),
      (DateTime(2026, 12, 11, 8), -1),
    ]);
    expect(times, hasLength(3 + BillReminders.overdueDays));
  });

  test('past reminders are dropped', () {
    final bill = _bill(due: DateTime(2026, 12, 10));
    final times = BillReminders.times(bill, DateTime(2026, 12, 8, 9), 8 * 60);
    expect(times.first.at, DateTime(2026, 12, 10, 8));
  });
}
