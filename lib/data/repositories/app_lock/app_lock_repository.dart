import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';

/// Why unlocking or confirming failed.
enum AppLockProblem {
  /// The prompt was closed without an answer.
  cancelled,

  /// The phone has no fingerprint, face or screen lock set up.
  noScreenLock,

  /// Too many failed tries; the phone blocks attempts for a while.
  lockedOut,

  /// Anything else.
  failed,
}

class AppLockException implements Exception {
  const AppLockException(this.problem);

  final AppLockProblem problem;

  @override
  String toString() => 'AppLockException(${problem.name})';
}

/// Keeps the app covered until the owner proves it's them with the
/// phone's fingerprint, face or screen lock, when the app lock preference
/// is on.
///
/// The app locks when it starts and when it comes back after [lockAfter]
/// or more away. A short trip out (the photo gallery, the share sheet)
/// leaves it open.
abstract class AppLockRepository extends ChangeNotifier {
  /// How long the app can be away before it locks again.
  static const Duration lockAfter = Duration(minutes: 1);

  /// Whether the app is covered by the lock screen.
  bool get isLocked;

  /// Whether this phone can check it's the owner (a screen lock is set).
  Future<bool> isAvailable();

  /// Asks for the fingerprint, face or screen lock and unlocks on success.
  /// A phone without a screen lock unlocks straight away, so the owner is
  /// never shut out.
  Future<Result<void>> unlock();

  /// Asks for the fingerprint, face or screen lock without changing the
  /// lock, e.g. before turning the lock on.
  Future<Result<void>> confirm();

  /// The app left the screen.
  void appHidden();

  /// The app is back on screen; locks when it was away long enough.
  void appResumed();
}
