import 'package:flutter_expensetracker/ui/activity/view_models/activity_view_model.dart';
import 'package:flutter_expensetracker/ui/history/view_models/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  HistoryViewModel build() {
    final viewModel = HistoryViewModel(
      transactionRepository: instantTransactionRepository(now: now),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  group('HistoryViewModel', () {
    test('groups every transaction by month, newest first', () async {
      final vm = build();
      await vm.load.execute();

      // This month and the five before it.
      expect(vm.months.map((m) => m.month), [
        DateTime(2026, 11),
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2026, 8),
        DateTime(2026, 7),
        DateTime(2026, 6),
      ]);
      final total = vm.months.fold<int>(
        0,
        (sum, m) => sum + m.transactions.length,
      );
      expect(vm.visibleCount, total);
    });

    test('works out each month in and out', () async {
      final vm = build();
      await vm.load.execute();

      final november = vm.months.first;
      expect(vm.incomeIn(november), 12500);
      expect(vm.expensesIn(november), 7680);
    });

    test('filters without dropping months, and recounts', () async {
      final vm = build();
      await vm.load.execute();
      final months = vm.months;

      vm.setFilter(ActivityFilter.income);

      expect(vm.months, months);
      expect(vm.expensesIn(vm.months.first), 0);
      expect(vm.incomeIn(vm.months.first), 12500);
      expect(
        vm.visibleCount,
        months.expand((m) => m.transactions).where((t) => t.isIncome).length,
      );
      expect(vm.hasNoMatches, isFalse);
    });
  });
}
