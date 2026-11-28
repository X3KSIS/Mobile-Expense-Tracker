import 'package:flutter/foundation.dart';

import '../../../data/repositories/app_lock/app_lock_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the lock screen that covers the app until the owner unlocks
/// it.
class AppLockViewModel extends ChangeNotifier {
  AppLockViewModel({required this._appLockRepository}) {
    _appLockRepository.addListener(_onLockChanged);
    unlock = Command0<void>(_unlock);
  }

  final AppLockRepository _appLockRepository;

  late final Command0<void> unlock;

  String? _message;
  bool _disposed = false;

  bool get isLocked => _appLockRepository.isLocked;

  /// Why the last try didn't unlock, or null.
  String? get message => _message;

  void appHidden() => _appLockRepository.appHidden();

  void appResumed() => _appLockRepository.appResumed();

  Future<Result<void>> _unlock() async {
    final result = await _appLockRepository.unlock();
    _message = switch (result) {
      Ok() => null,
      Error(:final error) => describe(error),
    };
    _notify();
    return result;
  }

  /// Words for a failed try. Closing the prompt needs none.
  static String? describe(Exception error) => switch (error) {
    AppLockException(problem: AppLockProblem.cancelled) => null,
    AppLockException(problem: AppLockProblem.lockedOut) =>
      'Too many tries. Wait a moment, then try again.',
    _ => "Couldn't check it's you. Please try again.",
  };

  void _onLockChanged() {
    if (isLocked) _message = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _appLockRepository.removeListener(_onLockChanged);
    unlock.dispose();
    super.dispose();
  }
}
