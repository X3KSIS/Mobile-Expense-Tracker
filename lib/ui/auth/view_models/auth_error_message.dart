import '../../../domain/models/auth_exception.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// User-facing text for a failed auth call.
String authErrorMessage(Exception error) {
  final code = error is AuthException ? error.code : AuthErrorCode.unknown;
  return switch (code) {
    AuthErrorCode.invalidCredentials =>
      "That email and password don't match. Check them and try again.",
    AuthErrorCode.emailAlreadyInUse =>
      'An account with this email already exists. Sign in instead.',
    AuthErrorCode.weakPassword =>
      'Choose a stronger password with at least 8 characters.',
    AuthErrorCode.confirmEmail =>
      "We've sent you a link to confirm your email. Open it, then sign in.",
    AuthErrorCode.emailNotConfirmed =>
      'Confirm your email first: open the link we sent you, then sign in.',
    AuthErrorCode.unsyncedChanges =>
      "Some changes haven't been saved online yet. Connect to the internet "
          'and try again, so nothing is lost.',
    AuthErrorCode.notSignedIn => 'Your session has ended. Sign in again.',
    AuthErrorCode.network =>
      "Couldn't reach Expense Tracker. Check your connection and try again.",
    AuthErrorCode.unknown => 'Something went wrong. Please try again.',
  };
}

/// The error message from [command]'s last run, or null if it did not fail.
String? commandErrorMessage(Command<Object?> command) =>
    switch (command.result) {
      Error(:final error) => authErrorMessage(error),
      _ => null,
    };
