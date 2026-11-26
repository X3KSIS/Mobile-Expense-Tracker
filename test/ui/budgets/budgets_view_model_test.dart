import 'package:flutter_expensetracker/data/repositories/category/fake_categories.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/budget_progress.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/ui/budgets/view_models/budgets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  ({BudgetsViewModel viewModel, TransactionRepositoryLocalFake transactions})
  build() {
    final transactions = instantTransactionRepository(now: now);
    final viewModel = BudgetsViewModel(
      budgetRepository: instantBudgetRepository(),
      transactionRepository: transactions,
      categoryRepository: instantCategoryRepository(),
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    return (viewModel: viewModel, transactions: transactions);
  }

  group('BudgetsViewModel', () {
    test('shows each budget\'s progress, most used first', () async {
      final viewModel = build().viewModel;

      await viewModel.load.execute();

      final names = viewModel.progress.map((p) => p.budget.categoryName);
      expect(names.first, 'Groceries');
      expect(viewModel.progress.first.percentRounded, 97);
      expect(viewModel.totalLimit, 3300 + 1500 + 800 + 300 + 600);
      expect(viewModel.totalSpent, 3200 + 530 + 300 + 150);
      expect(viewModel.overCount, 0);
    });

    test('counts the days left in the month', () {
      final viewModel = build().viewModel;

      // 25 to 30 November inclusive.
      expect(viewModel.daysLeft, 6);
    });

    test('offers only categories without a budget', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();

      final names = viewModel.availableCategories.map((c) => c.name);

      expect(names, contains('Housing'));
      expect(names, isNot(contains('Groceries')));
    });

    test('adds a budget for a new category', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();

      await viewModel.save.execute((
        budget: null,
        category: FakeCategories.housing,
        limit: '4,000',
      ));
      await viewModel.load.execute();

      final housing = viewModel.progress.firstWhere(
        (p) => p.budget.categoryName == 'Housing',
      );
      expect(housing.budget.limit, 4000);
      expect(housing.spent, 3500);
    });

    test('edits a limit and deletes a budget', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();
      final airtime = viewModel.progress
          .firstWhere((p) => p.budget.categoryName == 'Airtime')
          .budget;

      await viewModel.save.execute((
        budget: airtime,
        category: null,
        limit: '100',
      ));
      await viewModel.load.execute();
      final edited = viewModel.progress.firstWhere(
        (p) => p.budget.categoryName == 'Airtime',
      );
      expect(edited.isOverLimit, isTrue);
      expect(viewModel.overCount, 1);

      await viewModel.delete.execute(airtime.id);
      await viewModel.load.execute();
      expect(
        viewModel.progress.any((p) => p.budget.categoryName == 'Airtime'),
        isFalse,
      );
    });

    test('new expenses move the progress', () async {
      final built = build();
      final viewModel = built.viewModel;
      await viewModel.load.execute();

      await built.transactions.addTransaction(
        TransactionDraft(
          title: 'Spar',
          amount: 300,
          category: FakeCategories.groceries,
          date: now,
        ),
      );
      await viewModel.load.execute();

      final groceries = viewModel.progress.first;
      expect(groceries.spent, 3500);
      expect(groceries.isOverLimit, isTrue);
    });

    test('gives each budget a status', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();

      BudgetStatus statusOf(String name) => viewModel.progress
          .firstWhere((p) => p.budget.categoryName == name)
          .status;
      expect(statusOf('Groceries'), BudgetStatus.nearLimit);
      expect(statusOf('Transport'), BudgetStatus.onTrack);
      expect(statusOf('Eating out'), BudgetStatus.notStarted);
    });

    test('works out the daily allowance and average', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();

      final groceries = viewModel.progress.first;
      // ZMW 100 left over the 6 days from 25 to 30 November.
      expect(viewModel.dailyAllowance(groceries), closeTo(100 / 6, 0.001));
      // ZMW 3,200 over the first 25 days.
      expect(viewModel.dailyAverage(groceries), 128);
    });

    test('reorders budgets straight away and keeps the order', () async {
      final viewModel = build().viewModel;
      await viewModel.load.execute();
      List<String> names() =>
          viewModel.progress.map((p) => p.budget.categoryName).toList();
      final before = names();

      final saving = viewModel.reorder.execute((0, 2));
      expect(names(), [before[1], before[2], before[0], ...before.skip(3)]);
      await saving;
      await viewModel.load.execute();

      expect(names(), [before[1], before[2], before[0], ...before.skip(3)]);
    });

    test('validates the limit', () {
      final viewModel = build().viewModel;

      expect(viewModel.validateLimit(''), 'Enter a monthly limit');
      expect(viewModel.validateLimit('0'), 'The limit must be more than zero');
      expect(viewModel.validateLimit('1,500'), isNull);
    });
  });
}
