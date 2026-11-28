import 'package:flutter_expensetracker/ui/reports/view_models/reports_view_model.dart';
import 'package:flutter_expensetracker/ui/reports/widgets/spending_heatmap.dart';
import 'package:flutter_expensetracker/ui/reports/widgets/spending_trend_chart.dart';
import 'package:flutter_expensetracker/utils/currency.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15);

  Future<ReportsViewModel> loaded() async {
    final viewModel = ReportsViewModel(
      transactionRepository: instantTransactionRepository(now: now),
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load.execute();
    return viewModel;
  }

  group('ReportsViewModel', () {
    test('starts on the current month with its totals', () async {
      final viewModel = await loaded();

      expect(viewModel.month, DateTime(2026, 11));
      expect(viewModel.totals.income, 12500);
      expect(viewModel.totals.expenses, 7680);
      expect(viewModel.totals.net, 4820);
      expect(viewModel.previousTotals.month, DateTime(2026, 10));
      expect(viewModel.previousTotals.expenses, greaterThan(0));
    });

    test('breaks spending down by category, largest first', () async {
      final viewModel = await loaded();

      final categories = viewModel.categories;

      expect(categories.map((c) => c.name).take(3), [
        'Housing',
        'Groceries',
        'Transport',
      ]);
      expect(categories.first.amount, 3500);
      expect(categories.fold(0.0, (sum, c) => sum + c.share), closeTo(1, 1e-9));
    });

    test('the trend covers six months ending this month', () async {
      final viewModel = await loaded();

      final trend = viewModel.trend;

      expect(trend, hasLength(6));
      expect(trend.first.month, DateTime(2026, 6));
      expect(trend.last.month, DateTime(2026, 11));
      expect(trend.last.expenses, 7680);
    });

    test('moves between months within the trend range', () async {
      final viewModel = await loaded();

      expect(viewModel.canGoForward, isFalse);
      viewModel.goBack();
      expect(viewModel.month, DateTime(2026, 10));
      expect(viewModel.canGoForward, isTrue);

      for (var i = 0; i < 10; i++) {
        viewModel.goBack();
      }
      expect(viewModel.month, DateTime(2026, 6));
      expect(viewModel.canGoBack, isFalse);

      viewModel.selectMonth(DateTime(2026, 9, 14));
      expect(viewModel.month, DateTime(2026, 9));
    });

    test(
      'the month picker reaches back to the first month with data',
      () async {
        final viewModel = await loaded();

        expect(viewModel.earliestMonth, DateTime(2026, 6));
        expect(viewModel.spentIn(DateTime(2026, 11)), 7680);
        expect(viewModel.spentIn(DateTime(2026, 1)), 0);
      },
    );

    test('lists every day of the month with its spending', () async {
      final viewModel = await loaded();

      final days = viewModel.days;

      expect(days, hasLength(30));
      expect(days.fold(0.0, (sum, d) => sum + d.amount), 7680);
      expect(viewModel.isFuture(DateTime(2026, 11, 26)), isTrue);
      expect(viewModel.isFuture(DateTime(2026, 11, 25)), isFalse);
    });

    test('selecting a day toggles it, and changing month clears it', () async {
      final viewModel = await loaded();

      viewModel.selectDay(DateTime(2026, 11, 25));
      expect(viewModel.selectedDay!.amount, 640);
      viewModel.selectDay(DateTime(2026, 11, 25));
      expect(viewModel.selectedDay, isNull);

      viewModel.selectDay(DateTime(2026, 11, 7));
      viewModel.goBack();
      expect(viewModel.selectedDay, isNull);
    });
  });

  group('chart helpers', () {
    test('niceCeiling rounds up to a clean axis maximum', () {
      expect(SpendingTrendChart.niceCeiling(7680), 8000);
      expect(SpendingTrendChart.niceCeiling(10400), 12000);
      expect(SpendingTrendChart.niceCeiling(4100), 5000);
      expect(SpendingTrendChart.niceCeiling(1500), 1500);
      expect(SpendingTrendChart.niceCeiling(0), 1000);
    });

    test('heatmap levels split spending into quartiles', () {
      expect(SpendingHeatmap.level(0, 100), 0);
      expect(SpendingHeatmap.level(10, 100), 1);
      expect(SpendingHeatmap.level(50, 100), 2);
      expect(SpendingHeatmap.level(74, 100), 3);
      expect(SpendingHeatmap.level(100, 100), 4);
    });

    test('formatCompact shortens axis values', () {
      expect(formatCompact(0), '0');
      expect(formatCompact(950), '950');
      expect(formatCompact(5000), '5K');
      expect(formatCompact(12500), '12.5K');
      expect(formatCompact(1200000), '1.2M');
    });
  });
}
