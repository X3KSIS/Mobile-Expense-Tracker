import 'package:flutter_expensetracker/domain/models/spending_insight.dart';
import 'package:flutter_expensetracker/ui/core/ui/insight_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final november = DateTime(2026, 11);

  ({String title, String detail}) words(
    SpendingInsight i, {
    bool soFar = true,
  }) => describeInsight(i, month: november, monthToDate: soFar);

  test('a category rise, so far this month', () {
    final w = words(
      const SpendingInsight(
        kind: InsightKind.categoryUp,
        trend: InsightTrend.up,
        amount: 900,
        previous: 300,
        label: 'Eating out',
      ),
    );
    expect(w.title, 'Eating out up 200%');
    expect(
      w.detail,
      'ZMW 900.00 so far, against ZMW 300.00 by this point last month.',
    );
  });

  test('a category down to nothing', () {
    final w = words(
      const SpendingInsight(
        kind: InsightKind.categoryDown,
        trend: InsightTrend.down,
        amount: 0,
        previous: 420,
        label: 'Eating out',
      ),
    );
    expect(w.title, 'No eating out spending yet');
    expect(w.detail, 'Against ZMW 420.00 by this point last month. Well done.');
  });

  test('a new category has no percentage', () {
    final w = words(
      const SpendingInsight(
        kind: InsightKind.categoryUp,
        trend: InsightTrend.up,
        amount: 450,
        previous: 0,
        label: 'Health',
      ),
    );
    expect(w.title, 'New this month: Health');
  });

  test('past months compare with the whole previous month', () {
    final w = words(
      const SpendingInsight(
        kind: InsightKind.pace,
        trend: InsightTrend.down,
        amount: 800,
        previous: 1000,
      ),
      soFar: false,
    );
    expect(w.title, 'Spending is down 20%');
    expect(
      w.detail,
      'ZMW 800.00 in November, against ZMW 1,000.00 in October.',
    );
  });

  test('names the busiest weekday', () {
    final w = words(
      const SpendingInsight(
        kind: InsightKind.busiestDay,
        trend: InsightTrend.steady,
        amount: 300,
        previous: 50,
        label: '6',
      ),
    );
    expect(w.title, 'Saturdays cost you most');
  });
}
