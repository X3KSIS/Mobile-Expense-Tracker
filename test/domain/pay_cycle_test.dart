import 'package:flutter_expensetracker/domain/models/cycle_forecast.dart';
import 'package:flutter_expensetracker/domain/models/pay_cycle.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayCycle', () {
    test('runs from payday to the day before the next payday', () {
      final after = PayCycle.containing(DateTime(2026, 11, 26, 10), 25);
      expect(after.start, DateTime(2026, 11, 25));
      expect(after.end, DateTime(2026, 12, 25));

      final before = PayCycle.containing(DateTime(2026, 11, 10), 25);
      expect(before.start, DateTime(2026, 10, 25));
      expect(before.end, DateTime(2026, 11, 25));
    });

    test('payday 1 is the calendar month, across the year end', () {
      final cycle = PayCycle.containing(DateTime(2026, 12, 31), 1);
      expect(cycle.isCalendarMonth, isTrue);
      expect(cycle.start, DateTime(2026, 12));
      expect(cycle.end, DateTime(2027));
      expect(cycle.lengthInDays, 31);
    });

    test('counts days left and elapsed, including today', () {
      final now = DateTime(2026, 11, 26, 18);
      final cycle = PayCycle.containing(now, 25);
      expect(cycle.daysElapsed(now), 2);
      expect(cycle.daysLeft(now), 29);
    });

    test('clamps paydays past the 28th', () {
      final cycle = PayCycle.containing(DateTime(2027, 2, 28), 31);
      expect(cycle.start, DateTime(2027, 2, 28));
    });
  });

  group('CycleForecast', () {
    final now = DateTime(2026, 11, 30, 12);
    final cycle = PayCycle.containing(now, 25); // 25 Nov to 25 Dec.

    Transaction spend(double amount, DateTime date) => Transaction(
      id: '$amount$date',
      title: 'x',
      categoryName: 'x',
      categoryIcon: 'other',
      categoryColor: 0,
      amount: amount,
      type: TransactionType.expense,
      date: date,
    );

    CycleForecast forecast(double balance, double spentPerDay) =>
        CycleForecast.compute(
          cycle: cycle,
          now: now,
          balance: balance,
          transactions: [
            for (var d = 25; d <= 30; d++)
              spend(spentPerDay, DateTime(2026, 11, d, 9)),
            // Before the cycle, so it does not count.
            spend(9999, DateTime(2026, 11, 20)),
          ],
        );

    test('spreads the balance over the days left', () {
      final f = forecast(2500, 100);
      expect(f.safePerDay, 100); // 25 days left, counting today.
      expect(f.averagePerDay, 100);
    });

    test('is on track when the money lasts past payday', () {
      expect(forecast(5000, 100).status, ForecastStatus.onTrack);
    });

    test('is tight when it runs out just before payday', () {
      final f = forecast(2400, 100);
      expect(f.runsOutOn, DateTime(2026, 12, 24));
      expect(f.status, ForecastStatus.tight);
    });

    test('is short when it runs out well before payday', () {
      final f = forecast(1000, 100);
      expect(f.runsOutOn, DateTime(2026, 12, 10));
      expect(f.status, ForecastStatus.short);
    });

    test('is empty with nothing left', () {
      final f = forecast(0, 100);
      expect(f.status, ForecastStatus.empty);
      expect(f.safePerDay, 0);
    });

    test('is on track before anything is spent', () {
      final f = CycleForecast.compute(
        cycle: cycle,
        now: now,
        balance: 500,
        transactions: const [],
      );
      expect(f.runsOutOn, isNull);
      expect(f.status, ForecastStatus.onTrack);
    });
  });
}
