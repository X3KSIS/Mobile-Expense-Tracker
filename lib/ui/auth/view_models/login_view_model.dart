import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
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

  /// Whether sign-in is the demo account (no server configured).
  bool get isDemo => _authRepository.isDemo;

  /// Message for the last failed sign-in, or null.
  String? get errorMessage => commandErrorMessage(login);

  /// Hides the error banner, e.g. once the user edits a field.
  void clearError() => login.clearResult();

  Future<Result<void>> _login(LoginCredentials credentials) async {
    final result = await _authRepository.signIn(
      email: credentials.email.trim(),
      password: credentials.password,
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
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
