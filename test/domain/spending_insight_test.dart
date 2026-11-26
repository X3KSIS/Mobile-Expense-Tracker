import 'package:flutter_expensetracker/domain/models/spending_insight.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 26 November 2026, mid-afternoon.
  final now = DateTime(2026, 11, 26, 15);
  final month = DateTime(2026, 11);
  var id = 0;

  Transaction spend(
    double amount,
    DateTime date, {
    String category = 'Groceries',
    String? title,
    bool income = false,
  }) => Transaction(
    id: '${id++}',
    title: title ?? category,
    categoryName: category,
    categoryIcon: category.toLowerCase(),
    categoryColor: 0,
    amount: amount,
    type: income ? TransactionType.income : TransactionType.expense,
    date: date,
  );

  List<SpendingInsight> insights(List<Transaction> ts, {DateTime? forMonth}) =>
      SpendingInsights.compute(
        transactions: ts,
        month: forMonth ?? month,
        now: now,
      );

  SpendingInsight? find(List<SpendingInsight> list, InsightKind kind) =>
      list.where((i) => i.kind == kind).firstOrNull;

  test('compares this month so far with the same days last month', () {
    final list = insights([
      spend(1300, DateTime(2026, 11, 10)),
      spend(1000, DateTime(2026, 10, 10)),
      // After 26 October, so not in the comparison.
      spend(5000, DateTime(2026, 10, 28)),
      // Income never counts.
      spend(9000, DateTime(2026, 11, 2), income: true, category: 'Salary'),
    ]);

    final pace = find(list, InsightKind.pace)!;
    expect(pace.amount, 1300);
    expect(pace.previous, 1000);
    expect(pace.trend, InsightTrend.up);
    expect(pace.change, closeTo(0.3, 0.0001));

    final up = find(list, InsightKind.categoryUp)!;
    expect(up.label, 'Groceries');
    expect(up.icon, 'groceries');
    expect(up.amount - up.previous!, 300);
  });

  test('picks the biggest rise and the biggest fall', () {
    final list = insights([
      spend(900, DateTime(2026, 11, 5), category: 'Eating out'),
      spend(300, DateTime(2026, 10, 5), category: 'Eating out'),
      spend(500, DateTime(2026, 11, 5), category: 'Transport'),
      spend(400, DateTime(2026, 10, 5), category: 'Transport'),
      spend(100, DateTime(2026, 11, 5), category: 'Airtime'),
      spend(600, DateTime(2026, 10, 5), category: 'Airtime'),
    ]);

    expect(find(list, InsightKind.categoryUp)!.label, 'Eating out');
    expect(find(list, InsightKind.categoryDown)!.label, 'Airtime');
    // Rises come first; the fall comes near the end.
    expect(list.first.kind, InsightKind.categoryUp);
  });

  test('ignores small or tiny changes', () {
    final list = insights([
      spend(1020, DateTime(2026, 11, 5)),
      spend(1000, DateTime(2026, 10, 5)),
      spend(40, DateTime(2026, 11, 5), category: 'Airtime'),
      spend(20, DateTime(2026, 10, 5), category: 'Airtime'),
    ]);

    expect(find(list, InsightKind.categoryUp), isNull);
    expect(find(list, InsightKind.categoryDown), isNull);
    expect(find(list, InsightKind.pace)!.trend, InsightTrend.steady);
  });

  test('spots a category rising three months running', () {
    final list = insights([
      spend(400, DateTime(2026, 8, 3), category: 'Transport'),
      spend(500, DateTime(2026, 9, 3), category: 'Transport'),
      spend(650, DateTime(2026, 10, 3), category: 'Transport'),
      spend(300, DateTime(2026, 11, 3), category: 'Transport'),
    ]);

    final streak = find(list, InsightKind.risingStreak)!;
    expect(streak.label, 'Transport');
    expect(streak.count, 3);
    expect(streak.amount, 650);
    expect(streak.previous, 400);
  });

  test('finds the top place visited more than once', () {
    final list = insights([
      spend(640, DateTime(2026, 11, 20), title: 'Shoprite'),
      spend(1000, DateTime(2026, 11, 12), title: 'shoprite '),
      spend(3000, DateTime(2026, 11, 2), title: 'Furniture shop'),
    ]);

    final place = find(list, InsightKind.topPlace)!;
    expect(place.label, 'Shoprite');
    expect(place.amount, 1640);
    expect(place.count, 2);
  });

  test('adds up small spends', () {
    final list = insights([
      for (var d = 1; d <= 5; d++)
        spend(30, DateTime(2026, 11, d), category: 'Airtime'),
      spend(900, DateTime(2026, 11, 7)),
    ]);

    final small = find(list, InsightKind.smallSpends)!;
    expect(small.count, 5);
    expect(small.amount, 150);
  });

  test('names the busiest weekday when it clearly leads', () {
    final list = insights([
      // Every Saturday for 12 weeks: ZMW 300. Other days: ZMW 50 once.
      for (var w = 0; w < 12; w++)
        spend(300, DateTime(2026, 11, 21 - 7 * w, 11)),
      for (var d = 0; d < 6; d++) spend(50, DateTime(2026, 11, 16 + d, 11)),
    ]);

    final day = find(list, InsightKind.busiestDay)!;
    expect(day.label, '${DateTime.saturday}');
  });

  test('compares whole months for a past month', () {
    final list = insights([
      spend(1000, DateTime(2026, 9, 28)),
      spend(1500, DateTime(2026, 10, 28)),
    ], forMonth: DateTime(2026, 10));

    final pace = find(list, InsightKind.pace)!;
    expect(pace.amount, 1500);
    expect(pace.previous, 1000);
  });

  test('says nothing without data', () {
    expect(insights(const []), isEmpty);
  });
}
