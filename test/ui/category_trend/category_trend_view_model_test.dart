import 'package:flutter_expensetracker/ui/category_trend/view_models/category_trend_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/failing_transaction_repository.dart';
import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  CategoryTrendViewModel build({DateTime? month}) {
    final vm = CategoryTrendViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      categoryName: 'Groceries',
      month: month,
      clock: () => now,
    );
    addTearDown(vm.dispose);
    return vm;
  }

  test('shows the category over six months ending this month', () async {
    final vm = build();
    await vm.load.execute();

    final trend = vm.trend!;
    expect(vm.month, DateTime(2026, 11));
    expect(trend.months, hasLength(6));
    expect(trend.months.last.month, DateTime(2026, 11));
    expect(trend.monthToDate, isTrue);
    expect(trend.spent, greaterThan(0));
    expect(
      trend.transactions.every((t) => t.categoryName == 'Groceries'),
      isTrue,
    );
  });

  test('selecting a month keeps it inside the window', () async {
    final vm = build(month: DateTime(2026, 10));
    await vm.load.execute();
    expect(vm.month, DateTime(2026, 10));

    vm.selectMonth(DateTime(2025, 1));
    expect(vm.month, DateTime(2026, 6));

    vm.selectMonth(DateTime(2027, 3));
    expect(vm.month, DateTime(2026, 11));
  });

  test('an unknown category is empty', () async {
    final vm = CategoryTrendViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      categoryName: 'Yachts',
      clock: () => now,
    );
    addTearDown(vm.dispose);
    await vm.load.execute();

    expect(vm.isEmpty, isTrue);
  });

  test('a failed load shows the error', () async {
    final vm = CategoryTrendViewModel(
      transactionRepository: FailingTransactionRepository(
        instantTransactionRepository(now: now),
      ),
      categoryName: 'Groceries',
      clock: () => now,
    );
    addTearDown(vm.dispose);
    await vm.load.execute();

    expect(vm.hasError, isTrue);
  });
}
