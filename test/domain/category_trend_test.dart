import 'package:flutter_expensetracker/domain/models/category_trend.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/ui/category_trend/widgets/trend_summary_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Thursday 26 November 2026, mid-afternoon.
  final now = DateTime(2026, 11, 26, 15);
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

  CategoryTrend? trend(List<Transaction> ts, {DateTime? month}) =>
      CategoryTrends.compute(
        transactions: ts,
        categoryName: 'Groceries',
        month: month ?? DateTime(2026, 11),
        now: now,
      );

  test('totals each of the last six months, oldest first', () {
    final t = trend([
      spend(300, DateTime(2026, 9, 3)),
      spend(200, DateTime(2026, 9, 20)),
      spend(400, DateTime(2026, 11, 2)),
      spend(999, DateTime(2026, 4, 30)), // before the window
      spend(50, DateTime(2026, 11, 3), category: 'Transport'),
      spend(5000, DateTime(2026, 11, 1), income: true),
    ])!;

    expect(t.months.map((m) => m.month), [
      for (var m = 6; m <= 11; m++) DateTime(2026, m),
    ]);
    expect(t.months.map((m) => m.amount), [0, 0, 0, 500, 0, 400]);
    expect(t.months[3].count, 2);
    expect(t.spent, 400);
    expect(t.peak!.month, DateTime(2026, 9));
  });

  test('this month so far is compared with the same days before', () {
    final t = trend([
      spend(200, DateTime(2026, 9, 10)),
      spend(900, DateTime(2026, 9, 28)), // after the 26th: left out
      spend(400, DateTime(2026, 10, 5)),
      spend(450, DateTime(2026, 11, 20)),
    ])!;

    expect(t.monthToDate, isTrue);
    expect(t.usualMonths, 2);
    expect(t.usual, 300);
    expect(t.difference, 150);
    expect(t.change, closeTo(0.5, 0.0001));
    expect(describeComparison(t), contains('more than usual by this date'));
  });

  test('a past month is compared with whole months before it', () {
    final t = trend([
      spend(200, DateTime(2026, 8, 10)),
      spend(600, DateTime(2026, 8, 30)),
      spend(400, DateTime(2026, 10, 5)),
      spend(100, DateTime(2026, 11, 2)),
    ], month: DateTime(2026, 10))!;

    expect(t.monthToDate, isFalse);
    expect(t.usual, 800);
    expect(t.change, closeTo(-0.5, 0.0001));
    expect(describeComparison(t), startsWith('ZMW 400.00 (50%) less'));
  });

  test('small changes read as about the same', () {
    final t = trend([
      spend(500, DateTime(2026, 10, 5)),
      spend(520, DateTime(2026, 11, 5)),
    ])!;

    expect(describeComparison(t), startsWith('About the same as usual'));
  });

  test('the first month has nothing to compare with', () {
    final t = trend([spend(500, DateTime(2026, 11, 5))])!;

    expect(t.usual, isNull);
    expect(t.change, isNull);
    expect(describeComparison(t), 'Nothing earlier to compare with yet');
  });

  test('groups places by name and lists payments newest first', () {
    final t = trend([
      spend(300, DateTime(2026, 11, 2), title: 'Shoprite'),
      spend(100, DateTime(2026, 11, 9), title: 'shoprite '),
      spend(350, DateTime(2026, 11, 12), title: 'Pick n Pay'),
    ])!;

    expect(t.places.map((p) => p.title), ['shoprite', 'Pick n Pay']);
    expect(t.places.first.amount, 400);
    expect(t.places.first.count, 2);
    expect(t.places.first.average, 200);
    expect(t.transactions.map((x) => x.amount), [350, 100, 300]);
  });

  test('no spending in the window gives no trend', () {
    expect(trend([spend(100, DateTime(2026, 1, 5))]), isNull);
  });
}
