import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/auth_exception.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/auth_error_message.dart';
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

    test('signs in with any credentials', () async {
      await viewModel.login.execute((email: 'x', password: ''));

      expect(viewModel.login.completed, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(auth.isAuthenticated, isTrue);
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
  });

  group('authErrorMessage', () {
    test('maps every code to a message', () {
      for (final code in AuthErrorCode.values) {
        expect(authErrorMessage(AuthException(code)), isNotEmpty);
      }
      expect(
        authErrorMessage(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
