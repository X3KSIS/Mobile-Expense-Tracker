import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository_drift.dart';
import 'package:flutter_expensetracker/data/repositories/category/default_categories.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_drift.dart';
import 'package:flutter_expensetracker/data/services/database/app_database.dart';
import 'package:flutter_expensetracker/domain/models/budget.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_category.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/ui/categories/view_models/categories_view_model.dart';
import 'package:flutter_expensetracker/ui/categories/widgets/categories_screen.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

T _ok<T>(Result<T> r) => (r as Ok<T>).value;

void main() {
  group('CategoryRepositoryDrift', () {
    late AppDatabase db;
    late CategoryRepositoryDrift repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = CategoryRepositoryDrift(db);
      await repo.getCategories();
    });
    tearDown(() async {
      repo.dispose();
      await db.close();
    });

    test('adds a category at the end with a stored colour', () async {
      final pets = _ok(
        await repo.saveCategory(
          const TransactionCategory(
            id: '',
            name: '  Pets ',
            icon: 'pets',
            color: 0,
            type: TransactionType.expense,
          ),
        ),
      );
      expect(pets.name, 'Pets');
      expect(pets.color, isNot(0));
      final expenses = _ok(
        await repo.getCategories(type: TransactionType.expense),
      );
      expect(expenses.last.name, 'Pets');
    });

    test('refuses blank and duplicate names', () async {
      final blank = await repo.saveCategory(
        const TransactionCategory(
          id: '',
          name: ' ',
          icon: 'other',
          color: 0,
          type: TransactionType.expense,
        ),
      );
      expect(
        (blank as Error).error,
        isA<CategoryException>().having(
          (e) => e.problem,
          'problem',
          CategoryProblem.emptyName,
        ),
      );
      final dup = await repo.saveCategory(
        const TransactionCategory(
          id: '',
          name: 'groceries',
          icon: 'other',
          color: 0,
          type: TransactionType.expense,
        ),
      );
      expect(
        ((dup as Error).error as CategoryException).problem,
        CategoryProblem.duplicateName,
      );
    });

    test('renaming moves past transactions and budgets with it', () async {
      final transactions = TransactionRepositoryDrift(db);
      final budgets = BudgetRepositoryDrift(db);
      addTearDown(transactions.dispose);
      addTearDown(budgets.dispose);
      await transactions.addTransaction(
        TransactionDraft(
          title: 'Shoprite',
          amount: 300,
          category: DefaultCategories.groceries,
          date: DateTime(2026, 11, 20),
        ),
      );
      await budgets.saveBudget(
        Budget(
          id: '',
          categoryName: 'Groceries',
          categoryIcon: 'groceries',
          categoryColor: DefaultCategories.groceries.color,
          limit: 1500,
        ),
      );

      await repo.saveCategory(
        const TransactionCategory(
          id: 'c-groceries',
          name: 'Food shopping',
          icon: 'coffee',
          color: 0xFFE4572E,
          type: TransactionType.expense,
        ),
      );

      final t = _ok(await transactions.getTransactions()).single;
      expect(t.categoryName, 'Food shopping');
      expect(t.categoryIcon, 'coffee');
      final b = _ok(await budgets.getBudgets()).single;
      expect(b.categoryName, 'Food shopping');
      final row = await db.select(db.transactions).getSingle();
      expect(row.dirty, isTrue);
    });

    test('Fees & charges and the last of a type stay', () async {
      final fees = await repo.deleteCategory('c-fees');
      expect(
        ((fees as Error).error as CategoryException).problem,
        CategoryProblem.protected,
      );
      for (final c in _ok(
        await repo.getCategories(type: TransactionType.income),
      ).skip(1)) {
        await repo.deleteCategory(c.id);
      }
      final last = _ok(await repo.getCategories(type: TransactionType.income));
      expect(last, hasLength(1));
      final refused = await repo.deleteCategory(last.single.id);
      expect(
        ((refused as Error).error as CategoryException).problem,
        CategoryProblem.lastOfType,
      );
    });

    test('keeps the order the user chose', () async {
      final income = _ok(
        await repo.getCategories(type: TransactionType.income),
      );
      await repo.reorderCategories(TransactionType.income, [
        for (final c in income.reversed) c.id,
      ]);
      final after = _ok(await repo.getCategories(type: TransactionType.income));
      expect(after.map((c) => c.id), income.reversed.map((c) => c.id));
    });
  });

  test('the view model reorders at once and explains refusals', () async {
    final vm = CategoriesViewModel(
      categoryRepository: instantCategoryRepository(),
    );
    addTearDown(vm.dispose);
    await vm.load.execute();
    final first = vm.categories.first;

    await vm.reorder.execute((0, 2));
    expect(vm.categories[1], first);
    expect(
      CategoriesViewModel.messageFor(
        const CategoryException(CategoryProblem.duplicateName),
      ),
      contains('already have'),
    );
    expect(
      vm.canDelete(vm.categories.firstWhere((c) => c.id == 'c-fees')),
      isFalse,
    );
  });

  testWidgets('adding a category from the sheet', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final vm = CategoriesViewModel(
      categoryRepository: instantCategoryRepository(),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CategoriesScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.byTooltip('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Pets');
    await tester.tap(find.bySemanticsLabel('pets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.text('Category added'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pets'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pets'), findsOneWidget);
  });
}
