import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/login_view_model.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/sign_up_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/fake_repositories.dart';

void main() {
  group('LoginViewModel', () {
    late AuthRepositoryLocalFake auth;
    late LoginViewModel viewModel;

    setUp(() {
      auth = instantAuthRepository();
      viewModel = LoginViewModel(authRepository: auth);
    });

    tearDown(() => viewModel.dispose());

    test('signs in with the right credentials', () async {
      await viewModel.login.execute((
        email: AuthRepositoryLocalFake.demoEmail,
        password: AuthRepositoryLocalFake.demoPassword,
      ));

      expect(viewModel.login.completed, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(auth.isAuthenticated, isTrue);
    });

    test('shows a message for wrong credentials', () async {
      await viewModel.login.execute((
        email: AuthRepositoryLocalFake.demoEmail,
        password: 'nope',
      ));

      expect(viewModel.login.error, isTrue);
      expect(
        viewModel.errorMessage,
        "That email and password don't match. Check them and try again.",
      );
      expect(auth.isAuthenticated, isFalse);
    });

    test('clearError hides the message', () async {
      await viewModel.login.execute((email: 'x@y.com', password: 'nope'));
      expect(viewModel.errorMessage, isNotNull);

      viewModel.clearError();

      expect(viewModel.errorMessage, isNull);
    });

    test('resetPassword completes', () async {
      await viewModel.resetPassword.execute('someone@example.com');

      expect(viewModel.resetPassword.completed, isTrue);
    });
  });

  group('SignUpViewModel', () {
    late AuthRepositoryLocalFake auth;
    late SignUpViewModel viewModel;

    setUp(() {
      auth = instantAuthRepository();
      viewModel = SignUpViewModel(authRepository: auth);
    });

    tearDown(() => viewModel.dispose());

    test('creates the account and signs in', () async {
      await viewModel.signUp.execute((
        name: 'Mwila Banda',
        email: 'mwila@example.com',
        password: 'kwacha2026',
      ));

      expect(viewModel.signUp.completed, isTrue);
      expect(auth.currentUser!.name, 'Mwila Banda');
    });

    test('shows a message when the email is taken', () async {
      await viewModel.signUp.execute((
        name: 'Someone',
        email: AuthRepositoryLocalFake.demoEmail,
        password: 'kwacha2026',
      ));

      expect(
        viewModel.errorMessage,
        'An account with this email already exists. Sign in instead.',
      );
      expect(auth.isAuthenticated, isFalse);
    });
  });
}
