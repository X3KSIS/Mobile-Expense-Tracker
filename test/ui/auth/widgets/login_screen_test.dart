import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/login_view_model.dart';
import 'package:flutter_expensetracker/ui/auth/widgets/login_screen.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/core/ui/labeled_text_field.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/fake_repositories.dart';

void main() {
  late AuthRepositoryLocalFake auth;

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    auth = instantAuthRepository();
    final viewModel = LoginViewModel(authRepository: auth);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(viewModel: viewModel),
      ),
    );
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(LabeledTextField, label),
    matching: find.byType(TextFormField),
  );

  group('LoginScreen', () {
    testWidgets('validates empty fields without calling the repository', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('shows a banner for wrong credentials', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(field('Email'), 'demo@expensetrack.app');
      await tester.enterText(field('Password'), 'wrong-password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "That email and password don't match. Check them and try again.",
        ),
        findsOneWidget,
      );

      // Typing again hides the banner.
      await tester.enterText(field('Password'), 'password12');
      await tester.pump();
      expect(find.textContaining("don't match"), findsNothing);
    });

    testWidgets('signs in with the demo account', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(field('Email'), AuthRepositoryLocalFake.demoEmail);
      await tester.enterText(
        field('Password'),
        AuthRepositoryLocalFake.demoPassword,
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
    });

    testWidgets('the eye button toggles password visibility', (tester) async {
      await pumpLogin(tester);

      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('forgot password needs an email, then confirms', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(find.textContaining('Enter your email above'), findsOneWidget);

      await tester.enterText(field('Email'), 'mwila@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('If an account exists for mwila@example.com'),
        findsOneWidget,
      );
    });
  });
}
