import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/budget_progress.dart';
import 'package:flutter_expensetracker/domain/models/cycle_spending.dart';
import 'package:flutter_expensetracker/domain/models/pay_cycle.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _t(
  String id,
  String category,
  double amount,
  DateTime date, {
  TransactionType type = TransactionType.expense,
}) => Transaction(
  id: id,
  title: category,
  categoryName: category,
  categoryIcon: 'other',
  categoryColor: 0,
  amount: amount,
  type: type,
  date: date,
);

void main() {
  final now = DateTime(2026, 11, 10, 18);
  final cycle = PayCycle.containing(now, 1);

  test('totals this cycle, compares with the same point last cycle', () {
    final s = CycleSpending.compute(
      transactions: [
        _t('1', 'Food', 100, DateTime(2026, 11, 2)),
        _t('2', 'Food', 50, DateTime(2026, 11, 10, 9)),
        _t('3', 'Rent', 400, DateTime(2026, 11, 5)),
        _t(
          'i',
          'Salary',
          5000,
          DateTime(2026, 11, 1),
          type: TransactionType.income,
        ),
        // Last month: 300 by the 10th, 900 after.
        _t('4', 'Food', 300, DateTime(2026, 10, 4)),
        _t('5', 'Rent', 900, DateTime(2026, 10, 20)),
      ],
      budgets: const [],
      cycle: cycle,
      now: now,
    );
    expect(s.spent, 550);
    expect(s.lastCycleSoFar, 300);
    expect(s.change, 250);
    expect(s.daily, hasLength(30));
    expect(s.today, 9);
    expect(s.daily[1], 100);
    expect(s.daily[9], 50);
    expect(s.categories.map((c) => c.name), ['Rent', 'Food']);
    expect(s.categories.last.amount, 150);
  });

  test('nothing to compare with when last cycle had no spending', () {
    final s = CycleSpending.compute(
      transactions: [_t('1', 'Food', 100, DateTime(2026, 11, 2))],
      budgets: const [],
      cycle: cycle,
      now: now,
    );
    expect(s.lastCycleSoFar, isNull);
    expect(s.change, isNull);
  });

  test('categories carry their budget progress', () {
    final s = CycleSpending.compute(
      transactions: [_t('1', 'Food', 450, DateTime(2026, 11, 2))],
      budgets: const [
        Budget(
          id: 'b',
          categoryName: 'Food',
          categoryIcon: 'other',
          categoryColor: 0,
          limit: 500,
        ),
      ],
      cycle: cycle,
      now: now,
    );
    expect(s.categories.single.budget!.status, BudgetStatus.nearLimit);
  });
}
