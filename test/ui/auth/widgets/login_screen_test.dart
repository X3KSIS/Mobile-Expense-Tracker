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
    testWidgets('empty fields are checked before signing in', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email or username'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('any typed credentials sign in', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(field('Email or username'), 'anyone@example.com');
      await tester.enterText(field('Password'), 'anything');
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

    testWidgets('forgot password confirms with a snackbar', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(field('Email or username'), 'mwila@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(
        find.text("We've sent a password reset link to mwila@example.com."),
        findsOneWidget,
      );
    });
  });
}
