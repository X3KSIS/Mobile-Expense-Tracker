import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auth_error_message.dart';

/// Confirms a new account's email with the code Supabase sent. On success
/// the account is signed in and the router moves to Home.
class VerifyEmailViewModel extends ChangeNotifier {
  VerifyEmailViewModel({
    required this._authRepository,
    required this.email,
    this.resendWait = const Duration(seconds: 60),
  }) {
    verify = Command1<void, String>(_verify);
    resend = Command0<void>(_resend);
    _startCooldown();
  }

  final AuthRepository _authRepository;

  /// Where the code was sent.
  final String email;

  /// How long to wait before another code can be sent.
  final Duration resendWait;

  late final Command1<void, String> verify;
  late final Command0<void> resend;

  Timer? _ticker;
  int _secondsLeft = 0;
  bool _disposed = false;

  /// Seconds until [resend] is allowed again; 0 when it is.
  int get secondsUntilResend => _secondsLeft;

  bool get canResend => _secondsLeft == 0 && !resend.running;

  /// Message for the last failed attempt, or null.
  String? get errorMessage => commandErrorMessage(verify);

  void clearError() => verify.clearResult();

  /// Codes are digits only, 6 to 10 of them (Supabase's setting).
  static String? validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) return 'Enter the code from the email';
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      return 'The code is the 6 or more digits in the email';
    }
    return null;
  }

  Future<Result<void>> _verify(String code) async {
    final result = await _authRepository.verifyEmail(email: email, code: code);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<void>> _resend() async {
    final result = await _authRepository.resendEmailCode(email);
    if (result is Ok) _startCooldown();
    return result;
  }

  void _startCooldown() {
    _ticker?.cancel();
    _secondsLeft = resendWait.inSeconds;
    if (_secondsLeft == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft = (_secondsLeft - 1).clamp(0, resendWait.inSeconds);
      if (_secondsLeft == 0) timer.cancel();
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    verify.dispose();
    resend.dispose();
    super.dispose();
  }
}
