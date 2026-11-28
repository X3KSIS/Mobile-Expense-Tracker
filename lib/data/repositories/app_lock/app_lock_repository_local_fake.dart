import '../../../utils/result.dart';
import 'app_lock_repository.dart';

/// [AppLockRepository] for tests: every check gives [problem], or succeeds
/// when it is null.
class AppLockRepositoryLocalFake extends AppLockRepository {
  AppLockRepositoryLocalFake({
    this._locked = false,
    this.available = true,
    this.problem,
  });

  bool _locked;

  /// Whether the phone has a screen lock.
  bool available;

  /// What the next checks fail with; null succeeds.
  AppLockProblem? problem;

  /// How many times the prompt was shown.
  int prompts = 0;

  @override
  bool get isLocked => _locked;

  /// Covers the app, as coming back after a while would.
  void lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<void>> unlock() async {
    final result = await confirm();
    if (result case Ok()) {
      if (_locked) {
        _locked = false;
        notifyListeners();
      }
    }
    return result;
  }

  @override
  Future<Result<void>> confirm() async {
    prompts++;
    final failure = problem;
    return failure == null
        ? const Result.ok(null)
        : Result.error(AppLockException(failure));
  }

  @override
  void appHidden() {}

  @override
  void appResumed() {}
}
