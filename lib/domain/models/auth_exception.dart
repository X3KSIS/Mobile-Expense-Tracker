/// Why an authentication call failed.
enum AuthErrorCode {
  /// Wrong email or password.
  invalidCredentials,

  /// Sign-up with an email that already has an account.
  emailAlreadyInUse,

  /// The password does not meet the strength rules.
  weakPassword,

  /// Sign-up worked, but the email must be confirmed (a link was sent)
  /// before signing in.
  confirmEmail,

  /// Sign-in before the email was confirmed.
  emailNotConfirmed,

  /// Signing out now would lose changes not yet saved to the server.
  unsyncedChanges,

  /// The call needs a signed-in user and there is none.
  notSignedIn,

  /// The server could not be reached.
  network,

  /// Anything else.
  unknown,
}

/// Returned inside `Result.error` by the auth repository.
class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthException(${code.name})';
}
