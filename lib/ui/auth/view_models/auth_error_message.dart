import '../../../domain/models/auth_exception.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// User-facing text for a failed auth call.
String authErrorMessage(Exception error) {
  final code = error is AuthException ? error.code : AuthErrorCode.unknown;
  return switch (code) {
    AuthErrorCode.invalidCredentials =>
      "That email or username and password don't match. Check them and "
          'try again.',
    AuthErrorCode.emailAlreadyInUse =>
      'An account with this email already exists. Sign in instead.',
    AuthErrorCode.weakPassword =>
      'Choose a stronger password with at least 8 characters.',
    AuthErrorCode.confirmEmail =>
      "We've emailed you a code. Enter it to confirm your email.",
    AuthErrorCode.emailNotConfirmed =>
      'Confirm your email first with the code we sent you.',
    AuthErrorCode.samePassword =>
      'Choose a new password that is different from the current one.',
    AuthErrorCode.wrongPassword =>
      "Your current password isn't right. Check it and try again.",
    AuthErrorCode.invalidCode =>
      "That code is wrong or has expired. Check it, or send a new one.",
    AuthErrorCode.tooManyRequests =>
      'Too many tries. Wait a minute, then try again.',
    AuthErrorCode.unsyncedChanges =>
      "Some changes haven't been saved online yet. Connect to the internet "
          'and try again, so nothing is lost.',
    AuthErrorCode.notSignedIn => 'Your session has ended. Sign in again.',
    AuthErrorCode.usernameTaken => 'That username is taken. Try another one.',
    AuthErrorCode.usernameInvalid =>
      'Use 3 to 20 letters, numbers, dots or underscores for your username.',
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
