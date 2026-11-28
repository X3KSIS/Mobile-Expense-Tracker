import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_local_fake.dart';
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

    expect(find.text('Paul'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the Home toggle switches between light and dark', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.text('Paul'))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('empty fields are checked before signing in', (tester) async {
    await pumpApp(tester);
    await finishSplash(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email or username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(
      field('Email or username'),
      AuthRepositoryLocalFake.demoEmail,
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text(AuthRepositoryLocalFake.demoName.split(' ').first),
      findsOneWidget,
    );
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
    final passwords = find.byType(TextFormField);
    await tester.enterText(passwords.at(2), 'kwacha2026');
    await tester.enterText(passwords.at(3), 'kwacha2026');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Mwila'), findsOneWidget);
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
    expect(find.text('SPENT ON BUDGETS'), findsOneWidget);
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
      await scrollTo(tester, find.text('Save expense'));
      await tester.tap(find.text('Save expense'));
    }

    await scrollTo(tester, find.text('Title (optional)'));
    await tester.enterText(field('Title (optional)'), 'Hungry Lion');
    await tester.ensureVisible(find.bySemanticsLabel('Eating out'));
    await tester.pumpAndSettle();
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
    expect(find.text('SPENT THIS WEEK'), findsNothing);
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
    expect(find.text('SPENT THIS WEEK'), findsOneWidget);
  });

  testWidgets('Home shows a spending habit and opens the rest in Reports', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await scrollTo(tester, find.text('YOUR SPENDING HABITS'));
    expect(find.text('YOUR SPENDING HABITS'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'See all').first);
    await tester.pumpAndSettle();

    expect(find.text('Your habits'), findsOneWidget);
    expect(find.text('What stands out so far this month'), findsOneWidget);
  });

  testWidgets('Reports lists regular payments and opens them all', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Reports'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Regular payments'));
    final seeAll = find.textContaining('regular payments').last;
    await scrollTo(tester, seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.text('GOES OUT EVERY MONTH'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('DStv Compact'), findsWidgets);
  });

  testWidgets('Reports opens a category trend from the breakdown', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Reports'));
    await tester.pumpAndSettle();

    final groceries = find.bySemanticsLabel(RegExp(r'^Groceries: '));
    await scrollTo(tester, groceries);
    await tester.tap(groceries);
    await tester.pumpAndSettle();

    expect(find.text('SPENT SO FAR IN NOVEMBER'), findsOneWidget);
    expect(find.text('Last 6 months'), findsOneWidget);
    await scrollTo(tester, find.text('Where it went'));
    expect(find.text('Where it went'), findsOneWidget);
  });

  testWidgets('Activity shows the week and opens the full History', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Last 7 days'), findsOneWidget);
    await scrollTo(tester, find.text('See all activity'));
    await tester.tap(find.text('See all activity'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Income').last);
    await tester.pumpAndSettle();
    expect(find.text('Shoprite'), findsNothing);
    expect(find.text('Out ZMW 0.00'), findsWidgets);
  });

  testWidgets('a transaction can be edited from its details', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shoprite').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsOneWidget);
    final amount = find.byType(TextFormField).first;
    expect(find.descendant(of: amount, matching: find.text('640')), findsOne);
    await tester.enterText(amount, '655');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('-ZMW 655.00'), findsWidgets);
    expect(find.text('-ZMW 640.00'), findsNothing);
  });

  testWidgets('Activity filters and deletes', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.bySemanticsLabel('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('SPENT THIS WEEK'), findsOneWidget);

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

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('-ZMW 640.00'), findsWidgets);
  });

  testWidgets('Budgets adds, edits and deletes a budget', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    await tester.tap(find.bySemanticsLabel('Budgets'));
    await tester.pumpAndSettle();

    expect(find.text('ZMW 3,200 of 3,300'), findsOneWidget);
    expect(find.text('ZMW 100.00'), findsOneWidget);

    // Add a Housing budget (ZMW 3,500 already spent this month).
    await tester.tap(find.byTooltip('Add budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Housing'));
    await tester.enterText(field('Monthly limit (ZMW)'), '3000');
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget added'), findsOneWidget);
    // New budgets join the end of the list.
    final over = find.text('ZMW 3,500 of 3,000');
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
    expect(find.text('ZMW 3,500 of 4,000'), findsOneWidget);

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
    expect(find.text('ZMW 3,500 of 4,000'), findsNothing);
    // Housing goes back to the suggestions, ready to budget again.
    expect(find.textContaining('Set '), findsWidgets);
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

    await tester.tap(find.bySemanticsLabel('Fill from a MoMo or bank message'));
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

    await scrollTo(tester, find.text('Hungry Lion Cairo Road'));
    expect(find.text('Hungry Lion Cairo Road'), findsOneWidget);
    await scrollTo(tester, find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Expense saved'), findsOneWidget);
    await scrollTo(tester, find.text('Hungry Lion Cairo Road'));
    expect(find.text('Hungry Lion Cairo Road'), findsOneWidget);
    expect(find.text('Charge: Hungry Lion Cairo Road'), findsOneWidget);
  });

  testWidgets('payments from notifications are reviewed, added or dismissed', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);
    expect(find.textContaining('from your messages'), findsNothing);

    // Turn on access from Profile.
    await tester.tap(find.bySemanticsLabel(RegExp('^Profile')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Payment messages'));
    await tester.tap(find.text('Payment messages'));
    await tester.pumpAndSettle();
    expect(find.text('Add payments without typing'), findsOneWidget);
    await tester.tap(find.text('Allow notification access'));
    await tester.pumpAndSettle();
    expect(
      find.text('2 waiting. Nothing is saved until you add it.'),
      findsOneWidget,
    );

    // Add opens the form already filled in.
    await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Chicken Inn Levy'));
    expect(find.text('Chicken Inn Levy'), findsOneWidget);
    await scrollTo(tester, find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(
      find.text('1 waiting. Nothing is saved until you add it.'),
      findsOneWidget,
    );

    // Dismiss the other, then Home has nothing waiting.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('Home shows a banner when payments are waiting', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ...instantAppProviders(signedIn: true),
          ChangeNotifierProvider<DetectedPaymentRepository>(
            create: (_) => DetectedPaymentRepositoryLocalFake(
              enabled: true,
              incoming: sampleMessages,
            ),
          ),
        ],
        child: const ExpenseTrackApp(),
      ),
    );
    await finishSplash(tester);

    expect(find.text('2 payments from your messages'), findsOneWidget);
    await tester.tap(find.text('2 payments from your messages'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken Inn Levy'), findsOneWidget);
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

  testWidgets('Where it went opens a category and its trend', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await scrollTo(tester, find.text('Where it went'));
    await tester.tap(find.text('Groceries').first);
    await tester.pumpAndSettle();

    expect(find.text('Where it went'), findsWidgets);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Payments'), findsOneWidget);
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
    expect(find.text('Paul'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^Good (morning|afternoon|evening)$')),
      findsOneWidget,
    );
  });

  testWidgets('Profile opens Preferences, which switches to dark', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Preferences'), 200);
    await tester.ensureVisible(find.text('Preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    // The Profile menu underneath says Preferences too; the page is on top.
    expect(find.text('Preferences'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Preferences').last);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('Profile opens Security to change the password', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();
    expect(find.text('Change password'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'kwacha2026');
    await tester.enterText(fields.at(1), 'newpass2026');
    await tester.enterText(fields.at(2), 'newpass2026');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('signing out from Profile returns to sign in', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Paul Mubanga'), findsNothing);
  });
}
