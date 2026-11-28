import '../../../utils/result.dart';
import '../../services/device_auth_service.dart';
import '../settings/settings_repository.dart';
import 'app_lock_repository.dart';

/// [AppLockRepository] using the phone's own fingerprint, face or screen
/// lock. Whether the lock is on is a setting ([SettingsRepository.appLock]),
/// so it is stored and synced with the account.
class AppLockRepositoryDevice extends AppLockRepository {
  AppLockRepositoryDevice(
    this._settings, {
    DeviceAuthService? service,
    DateTime Function()? clock,
    this.lockAfter = AppLockRepository.lockAfter,
  }) : _service = service ?? DeviceAuthService(),
       _clock = clock ?? DateTime.now,
       // Settings are loaded before the app starts, so a cold start opens
       // locked.
       _locked = _settings.appLock {
    _settings.addListener(_onSettingsChanged);
  }

  final SettingsRepository _settings;
  final DeviceAuthService _service;
  final DateTime Function() _clock;
  final Duration lockAfter;

  bool _locked;
  bool _asking = false;
  DateTime? _hiddenAt;

  @override
  bool get isLocked => _locked;

  @override
  Future<bool> isAvailable() => _service.isAvailable();

  @override
  Future<Result<void>> unlock() async {
    if (!_locked) return const Result.ok(null);
    final result = await _ask('Unlock Expense Tracker');
    if (result case Error(:final error)
        when error is! AppLockException ||
            error.problem != AppLockProblem.noScreenLock) {
      return result;
    }
    _setLocked(false);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> confirm() => _ask('Confirm it\'s you');

  Future<Result<void>> _ask(String reason) async {
    _asking = true;
    try {
      final outcome = await _service.authenticate(reason);
      return switch (outcome) {
        DeviceAuthOutcome.success => const Result.ok(null),
        DeviceAuthOutcome.cancelled => _problem(AppLockProblem.cancelled),
        DeviceAuthOutcome.noScreenLock => _problem(AppLockProblem.noScreenLock),
        DeviceAuthOutcome.lockedOut => _problem(AppLockProblem.lockedOut),
        DeviceAuthOutcome.failed => _problem(AppLockProblem.failed),
      };
    } finally {
      _asking = false;
      // The prompt (or the screen lock page) can send the app to the
      // background; that trip doesn't count as being away.
      _hiddenAt = null;
    }
  }

  static Result<void> _problem(AppLockProblem problem) =>
      Result.error(AppLockException(problem));

  @override
  void appHidden() {
    if (_asking) return;
    _hiddenAt ??= _clock();
  }

  @override
  void appResumed() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (_asking || hiddenAt == null || !_settings.appLock) return;
    if (_clock().difference(hiddenAt) >= lockAfter) _setLocked(true);
  }

  void _onSettingsChanged() {
    if (!_settings.appLock) _setLocked(false);
  }

  void _setLocked(bool locked) {
    if (locked == _locked) return;
    _locked = locked;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
