import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/home/view_models/home_view_model.dart';
import 'package:flutter_expensetracker/ui/home/widgets/home_screen.dart';
import 'package:flutter_expensetracker/ui/home/widgets/transaction_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/failing_transaction_repository.dart';
import '../../../testing/fakes/fake_repositories.dart';

void main() {
  Future<HomeViewModel> pumpHome(
    WidgetTester tester, {
    TransactionRepository? transactions,
  }) async {
    // A tall phone-sized viewport so the whole list is built.
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final viewModel = HomeViewModel(
      transactionRepository: transactions ?? instantTransactionRepository(),
      budgetRepository: instantBudgetRepository(),
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(viewModel: viewModel),
      ),
    );
    return viewModel;
  }

  group('HomeScreen', () {
    testWidgets('shows a spinner while loading', (tester) async {
      await pumpHome(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders the balance and the recent transactions', (
      tester,
    ) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Paul Mubanga'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      // Balance card
      expect(find.text('ZMW 4,820.00', findRichText: true), findsOneWidget);
      expect(find.text('+12,500'), findsOneWidget);
      expect(find.text('-7,680'), findsOneWidget);

      // Budget alert
      expect(find.text('Groceries is almost at its limit.'), findsOneWidget);
      expect(find.text('97%'), findsOneWidget);
      expect(find.text('ZMW 100 LEFT'), findsOneWidget);

      // Recent activity
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(5));
      expect(find.text('Shoprite'), findsOneWidget);
      expect(find.text('-ZMW 640.00'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('+ZMW 12,500.00'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('-ZMW 450.00'), findsOneWidget);
      expect(find.text('ZESCO units'), findsOneWidget);
      expect(find.text('-ZMW 300.00'), findsOneWidget);
    });

    testWidgets('the eye button hides and shows amounts', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hide amounts'));
      await tester.pump();

      expect(find.text('ZMW 4,820.00', findRichText: true), findsNothing);
      expect(find.text('+12,500'), findsNothing);
      expect(find.byTooltip('Show amounts'), findsOneWidget);

      await tester.tap(find.byTooltip('Show amounts'));
      await tester.pump();

      expect(find.text('ZMW 4,820.00', findRichText: true), findsOneWidget);
    });

    testWidgets('shows a retry view when loading fails', (tester) async {
      final repository = FailingTransactionRepository(
        instantTransactionRepository(),
      );
      await pumpHome(tester, transactions: repository);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your dashboard"), findsOneWidget);

      repository.shouldFail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('ZMW 4,820.00', findRichText: true), findsOneWidget);
    });
  });
}
