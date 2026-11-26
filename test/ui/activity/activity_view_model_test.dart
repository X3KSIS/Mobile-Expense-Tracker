import 'package:flutter_expensetracker/ui/activity/view_models/activity_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/failing_transaction_repository.dart';
import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  group('ActivityViewModel', () {
    test('groups every transaction by day, newest first', () async {
      final viewModel = ActivityViewModel(
        transactionRepository: instantTransactionRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);

      await viewModel.load.execute();

      final days = viewModel.days;
      expect(days, isNotEmpty);
      for (var i = 1; i < days.length; i++) {
        expect(days[i - 1].day.isAfter(days[i].day), isTrue);
      }
      // Today: Shoprite (-640) and Salary (+12,500).
      expect(days.first.transactions.map((t) => t.title), [
        'Shoprite',
        'Salary',
      ]);
      expect(days.first.net, 11860);
    });

    test('filters by type and updates the totals', () async {
      final viewModel = ActivityViewModel(
        transactionRepository: instantTransactionRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      viewModel.setFilter(ActivityFilter.income);

      final all = viewModel.days.expand((d) => d.transactions);
      expect(all.every((t) => t.isIncome), isTrue);
      expect(viewModel.totalOut, 0);
      expect(viewModel.totalIn, greaterThan(0));

      viewModel.setFilter(ActivityFilter.expenses);
      expect(
        viewModel.days.expand((d) => d.transactions).any((t) => t.isIncome),
        isFalse,
      );
    });

    test('keeps every day so the list can fold rows in and out', () async {
      final viewModel = ActivityViewModel(
        transactionRepository: instantTransactionRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();
      final everything = viewModel.allDays.expand((d) => d.transactions);

      viewModel.setFilter(ActivityFilter.income);
      expect(viewModel.allDays.expand((d) => d.transactions), everything);
      expect(
        everything.where(viewModel.isVisible).every((t) => t.isIncome),
        isTrue,
      );
      expect(
        everything.where(viewModel.isVisible).length,
        viewModel.visibleCount,
      );
      expect(viewModel.hasNoMatches, isFalse);
    });

    test('shows only the last 7 days, and counts the full history', () async {
      final viewModel = ActivityViewModel(
        transactionRepository: instantTransactionRepository(now: now),
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      final since = DateTime(2026, 11, 19);
      final recent = viewModel.allDays.expand((d) => d.transactions);
      expect(recent, isNotEmpty);
      expect(recent.every((t) => !t.date.isBefore(since)), isTrue);
      expect(viewModel.totalCount, greaterThan(recent.length));
      expect(viewModel.hasNoRecent, isFalse);
    });

    test('reloads after a delete', () async {
      final repository = instantTransactionRepository(now: now);
      final viewModel = ActivityViewModel(
        transactionRepository: repository,
        clock: () => now,
      );
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();
      final before = viewModel.visibleCount;

      await viewModel.delete.execute('t1');
      await viewModel.load.execute();

      expect(viewModel.visibleCount, before - 1);
    });

    test('exposes a load error', () async {
      final viewModel = ActivityViewModel(
        transactionRepository: FailingTransactionRepository(
          instantTransactionRepository(now: now),
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.load.execute();

      expect(viewModel.hasError, isTrue);
      expect(viewModel.isLoading, isFalse);
    });
  });
}
