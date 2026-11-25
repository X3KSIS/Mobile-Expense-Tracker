import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auth_error_message.dart';

typedef SignUpDetails = ({String name, String email, String password});

/// Creates an account. On success the user is signed in and the router
/// moves to Home.
class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({required this._authRepository}) {
    signUp = Command1<void, SignUpDetails>(_signUp);
  }

  final AuthRepository _authRepository;

  late final Command1<void, SignUpDetails> signUp;

  /// Message for the last failed sign-up, or null.
  String? get errorMessage => commandErrorMessage(signUp);

  /// Hides the error banner, e.g. once the user edits a field.
  void clearError() => signUp.clearResult();

  Future<Result<void>> _signUp(SignUpDetails details) async {
    final result = await _authRepository.signUp(
      name: details.name.trim(),
      email: details.email.trim(),
      password: details.password,
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  void dispose() {
    signUp.dispose();
    super.dispose();
  }
}
