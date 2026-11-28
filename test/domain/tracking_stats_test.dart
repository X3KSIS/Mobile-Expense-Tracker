import 'package:flutter_expensetracker/domain/models/tracking_stats.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _on(DateTime date) => Transaction(
  id: '${date.millisecondsSinceEpoch}',
  title: 'x',
  categoryName: 'Food',
  categoryIcon: 'other',
  categoryColor: 0,
  amount: 10,
  type: TransactionType.expense,
  date: date,
);

void main() {
  final now = DateTime(2026, 11, 28, 18);

  test('counts the streak, this month and months tracked', () {
    final stats = TrackingStats.compute([
      _on(DateTime(2026, 11, 28, 9)),
      _on(DateTime(2026, 11, 27, 9)),
      _on(DateTime(2026, 11, 26, 9)),
      _on(DateTime(2026, 11, 24, 9)), // gap on the 25th ends the streak
      _on(DateTime(2026, 10, 3)),
    ], now);
    expect(stats.streak, 3);
    expect(stats.thisMonth, 4);
    expect(stats.monthsTracked, 2);
  });

  test('nothing yet today keeps yesterday\'s streak going', () {
    final stats = TrackingStats.compute([
      _on(DateTime(2026, 11, 27, 9)),
      _on(DateTime(2026, 11, 26, 9)),
    ], now);
    expect(stats.streak, 2);
  });

  test('no transactions means no streak', () {
    expect(TrackingStats.compute(const [], now), TrackingStats.empty);
  });
}
