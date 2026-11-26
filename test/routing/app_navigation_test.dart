import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/main.dart';
import 'package:flutter_expensetracker/ui/core/ui/floating_nav_bar.dart';
import 'package:flutter_expensetracker/ui/core/ui/labeled_text_field.dart';
import 'package:flutter_expensetracker/ui/core/ui/primary_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../testing/fakes/fake_repositories.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {bool signedIn = false}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: instantAppProviders(signedIn: signedIn),
        child: const ExpenseTrackApp(),
      ),
    );
  }

  Future<void> finishSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(LabeledTextField, label),
    matching: find.byType(TextFormField),
  );

  testWidgets('signed out: splash opens the sign-in screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('ExpenseTrack'), findsOneWidget);
    expect(find.text('Know where your kwacha goes'), findsOneWidget);

    await finishSplash(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('signed in: splash opens Home', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    expect(find.text('Paul Mubanga'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the Home toggle switches between light and dark', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.text('Paul Mubanga'))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('tapping Sign in with empty fields goes to Home', (tester) async {
    await pumpApp(tester);
    await finishSplash(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text(AuthRepositoryLocalFake.demoName), findsOneWidget);
    await scrollTo(tester, find.text('Recent activity'));
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('signing up creates the account and goes to Home', (
    tester,
  ) async {
    await pumpApp(tester);
    await finishSplash(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.enterText(field('Full name'), 'Mwila Banda');
    await tester.enterText(field('Email'), 'mwila@example.com');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Mwila Banda'), findsOneWidget);
    expect(find.text('MB'), findsOneWidget);
  });

  testWidgets('sign up links back to sign in', (tester) async {
    await pumpApp(tester);
    await finishSplash(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('bottom bar switches tabs and + opens Add', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.bySemanticsLabel('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('SPENT THIS MONTH'), findsOneWidget);
    // The active tab shows its label next to the icon.
    expect(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Budgets'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('AMOUNT SPENT'), findsOneWidget);
  });

  testWidgets('an expense added with + shows on Home', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    Future<void> tapSave() async {
      // Unfocus so the focused field stops scrolling itself into view, then
      // drag to the bottom of the form.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save expense'));
    }

    await tester.enterText(field('Title (optional)'), 'Hungry Lion');
    await tester.tap(find.bySemanticsLabel('Eating out'));

    // Saving without an amount shows a validation error.
    await tapSave();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Enter an amount'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Enter an amount'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '85');
    await tapSave();
    await tester.pumpAndSettle();

    expect(find.text('Expense saved'), findsOneWidget);
    await scrollTo(tester, find.text('Hungry Lion'));
    expect(find.text('Hungry Lion'), findsOneWidget);
    expect(find.text('-ZMW 85.00'), findsOneWidget);
  });

  testWidgets('Activity opens a full-screen search', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Search transactions'));
    await tester.pumpAndSettle();

    // Only the search is on screen: no tabs, no totals.
    expect(find.byType(FloatingNavBar), findsNothing);
    expect(find.text('Money in'), findsNothing);
    expect(find.text('POPULAR CATEGORIES'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.enterText(find.byType(TextField), 'zesco');
    await tester.pumpAndSettle();
    expect(find.text('ZESCO units'), findsWidgets);
    expect(find.text('Shoprite'), findsNothing);

    // A suggestion fills the field.
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Shoprite'), findsWidgets);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.text('Money in'), findsOneWidget);
  });

  testWidgets('Activity filters and deletes', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Money in'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Income').last);
    await tester.pumpAndSettle();
    expect(find.text('Shoprite'), findsNothing);
    expect(find.text('Salary'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('All').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shoprite').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete transaction'), findsOneWidget);
    expect(find.text('-ZMW 640.00'), findsWidgets);

    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('-ZMW 640.00'), findsNothing);
  });

  testWidgets('Budgets adds, edits and deletes a budget', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('ZMW 3,200.00 of ZMW 3,300.00'), findsOneWidget);
    expect(find.text('ZMW 100.00 left'), findsOneWidget);

    // Add a Housing budget (ZMW 3,500 already spent this month).
    await tester.tap(find.byTooltip('Add budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Housing'));
    await tester.enterText(field('Monthly limit (ZMW)'), '3000');
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget added'), findsOneWidget);
    // New budgets join the end of the list.
    final over = find.text('ZMW 500.00 over');
    await tester.scrollUntilVisible(
      over,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(over, findsOneWidget);
    expect(find.text('Over budget'), findsOneWidget);

    // Tapping the card expands it; raise the limit from there.
    final edit = find.widgetWithText(TextButton, 'Edit');
    expect(edit, findsNothing);
    await tester.tap(find.text('Housing'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    expect(find.text('Left per day'), findsOneWidget);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(field('Monthly limit (ZMW)'), '4000');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(find.text('ZMW 3,500.00 of ZMW 4,000.00'), findsOneWidget);

    // The card is still open; delete the budget.
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Budget deleted'), findsOneWidget);
    expect(find.text('Housing'), findsNothing);
  });

  testWidgets('Home opens Wallets, where money moves between wallets', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await scrollTo(tester, find.text('MTN MoMo'));
    expect(find.text('MTN MoMo'), findsOneWidget);
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(find.text('MONEY YOU HAVE'), findsOneWidget);

    await tester.tap(find.text('Move money'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('MTN MoMo').first);
    await tester.enterText(field('Amount (ZMW)'), '200');
    await tester.enterText(field('Charge (optional)'), '5');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Move money').last);
    await tester.pumpAndSettle();

    expect(find.text('Money moved'), findsOneWidget);
    expect(find.text('MTN MoMo → Cash'), findsOneWidget);
  });

  testWidgets('a pasted MoMo message fills in and saves an expense', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fill from a message'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'You have paid ZMW 75.00 to HUNGRY LION CAIRO ROAD. Fee ZMW 1.00. '
      'Txn ID: 55501.',
    );
    await tester.pumpAndSettle();
    expect(find.text('Money out'), findsOneWidget);
    await tester.tap(find.text('Fill in the form'));
    await tester.pumpAndSettle();

    expect(find.text('Hungry Lion Cairo Road'), findsOneWidget);
    await scrollTo(tester, find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Expense saved'), findsOneWidget);
    await scrollTo(tester, find.text('Hungry Lion Cairo Road'));
    expect(find.text('Hungry Lion Cairo Road'), findsOneWidget);
    expect(find.text('Charge: Hungry Lion Cairo Road'), findsOneWidget);
  });

  testWidgets('Reports switches month and shows a day total', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('ZMW 7,680.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('ZMW 7,680.00'), findsNothing);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    final today = find.bySemanticsLabel(RegExp(r'^Today: spent'));
    await tester.scrollUntilVisible(
      today,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(today);
    await tester.pumpAndSettle();
    await tester.tap(today);
    await tester.pumpAndSettle();
    expect(find.textContaining('Today', findRichText: true), findsWidgets);
  });

  testWidgets('the Income quick action opens Add on Income', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await scrollTo(tester, find.bySemanticsLabel('Income'));
    await tester.tap(find.bySemanticsLabel('Income'));
    await tester.pumpAndSettle();

    expect(find.text('AMOUNT RECEIVED'), findsOneWidget);
    expect(find.bySemanticsLabel('Salary'), findsOneWidget);
  });

  testWidgets('avatar opens Profile, where details can be edited', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('demo@expensetrack.app'), findsOneWidget);
    expect(find.text('097 123 4567'), findsOneWidget);

    await tester.tap(find.text('Personal details'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Full name'), 'Paul M. Mubanga');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Paul M. Mubanga'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Paul M. Mubanga'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signing out from Profile returns to sign in', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Paul Mubanga'), findsNothing);
  });
}
