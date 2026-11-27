import 'package:flutter_expensetracker/data/repositories/category/default_categories.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/budget_progress.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

T _ok<T>(Result<T> result) => (result as Ok<T>).value;

void main() {
  group('TransactionRepositoryLocalFake', () {
    for (final now in [
      DateTime(2026, 11, 25, 15),
      DateTime(2026, 11, 2, 9),
      DateTime(2026, 1, 1, 8),
    ]) {
      test('current month totals stay fixed on $now', () async {
        final repo = instantTransactionRepository(now: now);

        final summary = _ok(await repo.getMonthlySummary());

        expect(summary.income, 12500);
        expect(summary.expenses, 7680);
        expect(summary.net, 4820);
      });
    }

    test('has five earlier months of history', () async {
      final now = DateTime(2026, 11, 25);
      final repo = instantTransactionRepository(now: now);

      for (var back = 1; back <= 5; back++) {
        final month = DateTime(now.year, now.month - back);
        final summary = _ok(await repo.getMonthlySummary(month: month));
        expect(summary.income, greaterThanOrEqualTo(12500));
        expect(summary.expenses, greaterThan(0));
      }
      final empty = _ok(await repo.getMonthlySummary(month: DateTime(2026, 5)));
      expect(empty.expenses, 0);
    });

    test('lists every transaction newest first', () async {
      final repo = instantTransactionRepository();

      final all = _ok(await repo.getTransactions());

      expect(all.length, greaterThan(9));
      for (var i = 1; i < all.length; i++) {
        expect(all[i - 1].date.isBefore(all[i].date), isFalse);
      }
    });

    test('adds and deletes, notifying each time', () async {
      final repo = instantTransactionRepository();
      var notified = 0;
      repo.addListener(() => notified++);

      final added = _ok(
        await repo.addTransaction(
          TransactionDraft(
            title: '  ',
            amount: 75,
            category: DefaultCategories.eatingOut,
            date: DateTime.now(),
            note: ' Lunch ',
          ),
        ),
      );

      expect(added.title, 'Eating out');
      expect(added.note, 'Lunch');
      expect(added.type, TransactionType.expense);
      expect(_ok(await repo.getRecentTransactions(limit: 1)).single, added);

      await repo.deleteTransaction(added.id);
      final all = _ok(await repo.getTransactions());
      expect(all.any((t) => t.id == added.id), isFalse);
      expect(notified, 2);
    });
  });

  group('BudgetProgress', () {
    test('works out this month\'s spending per budget', () async {
      final now = DateTime(2026, 11, 25);
      final budgets = _ok(await instantBudgetRepository().getBudgets());
      final transactions = _ok(
        await instantTransactionRepository(now: now).getTransactions(),
      );

      final progress = BudgetProgress.forMonth(budgets, transactions, now);
      final byName = {for (final p in progress) p.budget.categoryName: p};

      expect(byName['Groceries']!.spent, 3200);
      expect(byName['Groceries']!.percentRounded, 97);
      expect(byName['Groceries']!.remaining, 100);
      expect(byName['Transport']!.spent, 530);
      expect(byName['Eating out']!.spent, 0);

      final top = BudgetProgress.topAlert(progress)!;
      expect(top.budget.categoryName, 'Groceries');
    });

    test('over the limit reports how much over', () async {
      final budgets = _ok(await instantBudgetRepository().getBudgets());
      final airtime = budgets.firstWhere((b) => b.categoryName == 'Airtime');

      final progress = BudgetProgress(budget: airtime, spent: 450);

      expect(progress.isOverLimit, isTrue);
      expect(progress.overBy, 150);
      expect(progress.remaining, 0);
    });
  });

  group('BudgetRepositoryLocalFake', () {
    test('saves new and edited budgets, and deletes', () async {
      final repo = instantBudgetRepository();
      var notified = 0;
      repo.addListener(() => notified++);
      final initial = _ok(await repo.getBudgets());

      final groceries = initial.first;
      await repo.saveBudget(groceries.copyWith(limit: 4000));
      final created = _ok(
        await repo.saveBudget(
          const Budget(
            id: '',
            categoryName: 'Health',
            categoryIcon: 'health',
            categoryColor: 0xFF1F8A8A,
            limit: 500,
          ),
        ),
      );
      expect(created.id, isNotEmpty);
      expect(_ok(await repo.getBudgets()), hasLength(initial.length + 1));
      await repo.deleteBudget(created.id);

      final budgets = _ok(await repo.getBudgets());
      expect(budgets.first.limit, 4000);
      expect(budgets, hasLength(initial.length));
      expect(notified, 3);
    });
  });
}
