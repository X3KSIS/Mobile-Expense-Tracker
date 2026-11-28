import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// How asking the user to prove it's them ended.
enum DeviceAuthOutcome {
  /// Fingerprint, face or the phone's screen lock matched.
  success,

  /// The user (or the system) closed the prompt.
  cancelled,

  /// The phone has no fingerprint, face or screen lock set up.
  noScreenLock,

  /// Too many failed tries; the phone blocks attempts for a while.
  lockedOut,

  /// Anything else that went wrong.
  failed,
}

/// Wraps `local_auth`: the phone's own fingerprint, face or screen lock
/// (PIN, pattern or password). Stateless; used by AppLockRepository.
class DeviceAuthService {
  DeviceAuthService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the phone can check it's the owner (a screen lock is set).
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Shows the system prompt with [reason]. Falls back to the screen lock
  /// when there is no fingerprint or face.
  Future<DeviceAuthOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? DeviceAuthOutcome.success : DeviceAuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress => DeviceAuthOutcome.cancelled,
        LocalAuthExceptionCode.noCredentialsSet =>
          DeviceAuthOutcome.noScreenLock,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => DeviceAuthOutcome.lockedOut,
        _ => DeviceAuthOutcome.failed,
      };
    } on PlatformException {
      return DeviceAuthOutcome.failed;
    } on MissingPluginException {
      return DeviceAuthOutcome.noScreenLock;
    }
  }
}
