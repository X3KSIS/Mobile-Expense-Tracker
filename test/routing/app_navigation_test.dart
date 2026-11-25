import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/main.dart';
import 'package:flutter_expensetracker/ui/core/ui/labeled_text_field.dart';
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

  testWidgets('tapping Sign in with empty fields goes to Home', (tester) async {
    await pumpApp(tester);
    await finishSplash(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text(AuthRepositoryLocalFake.demoName), findsOneWidget);
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
    expect(find.text('Budgets is coming soon'), findsOneWidget);

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
    expect(find.text('Hungry Lion'), findsOneWidget);
    expect(find.text('-ZMW 85.00'), findsOneWidget);
  });

  testWidgets('the Income quick action opens Add on Income', (tester) async {
    await pumpApp(tester, signedIn: true);
    await finishSplash(tester);

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
