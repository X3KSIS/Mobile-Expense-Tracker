import 'package:flutter_expensetracker/data/repositories/budget/budget_repository.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../testing/fakes/fake_repositories.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TransactionRepository>(
            create: (_) => instantTransactionRepository(),
          ),
          Provider<BudgetRepository>(create: (_) => instantBudgetRepository()),
        ],
        child: const ExpenseTrackApp(),
      ),
    );
  }

  testWidgets('splash shows the wordmark, then opens Home', (tester) async {
    await pumpApp(tester);

    expect(find.text('ExpenseTrack'), findsOneWidget);
    expect(find.text('Know where your kwacha goes'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('bottom bar switches tabs and + opens Add', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('Budgets is coming soon'), findsOneWidget);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction is coming soon'), findsOneWidget);
  });
}
