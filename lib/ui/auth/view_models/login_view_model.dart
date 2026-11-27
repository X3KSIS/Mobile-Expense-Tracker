import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth_exception.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auth_error_message.dart';

typedef LoginCredentials = ({String email, String password});

/// Signs the user in. On success the router sees the auth change and moves
/// to Home, so the view does not navigate itself.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this._authRepository}) {
    login = Command1<void, LoginCredentials>(_login);
    resetPassword = Command1<void, String>(_resetPassword);
  }

  final AuthRepository _authRepository;

  late final Command1<void, LoginCredentials> login;

  /// Sends a reset link to the given email.
  late final Command1<void, String> resetPassword;

  /// Set when the account's email is not confirmed yet: a new code has
  /// been sent and the view opens the code screen.
  String? get emailToConfirm => _emailToConfirm;
  String? _emailToConfirm;

  /// Message for the last failed sign-in, or null.
  String? get errorMessage => commandErrorMessage(login);

  /// Hides the error banner, e.g. once the user edits a field.
  void clearError() => login.clearResult();

  Future<Result<void>> _login(LoginCredentials credentials) async {
    final result = await _authRepository.signIn(
      email: credentials.email.trim(),
      password: credentials.password,
    );
    switch (result) {
      case Ok():
        return const Result.ok(null);
      case Error(error: AuthException(code: AuthErrorCode.emailNotConfirmed)):
        final email = credentials.email.trim();
        await _authRepository.resendEmailCode(email);
        _emailToConfirm = email;
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _resetPassword(String email) =>
      _authRepository.sendPasswordResetEmail(email.trim());

  @override
  void dispose() {
    login.dispose();
    resetPassword.dispose();
    super.dispose();
  }
}
