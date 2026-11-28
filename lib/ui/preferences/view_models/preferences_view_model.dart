import 'package:flutter/foundation.dart';

import '../../../data/repositories/app_lock/app_lock_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

/// State for the Preferences page: theme, payday, budget warning level,
/// default wallet and what Home shows. Every change is saved through
/// [SettingsRepository], so it is stored and synced.
class PreferencesViewModel extends ChangeNotifier {
  PreferencesViewModel({
    required this._settingsRepository,
    required this._walletRepository,
    required this._appLockRepository,
  }) {
    _settingsRepository.addListener(_notify);
    _walletRepository.addListener(_onWalletsChanged);
    loadWallets = Command0<void>(_loadWallets)..execute();
    setAppLock = Command1<void, bool>(_setAppLock);
    _loadAppLockAvailable();
  }

  final SettingsRepository _settingsRepository;
  final WalletRepository _walletRepository;
  final AppLockRepository _appLockRepository;

  late final Command0<void> loadWallets;

  /// Turns the app lock on (after the owner confirms it's them) or off.
  late final Command1<void, bool> setAppLock;

  List<Wallet> _wallets = const [];
  bool _appLockAvailable = false;
  String? _appLockMessage;
  bool _disposed = false;

  // Appearance -------------------------------------------------------------

  ThemePreference get theme => _settingsRepository.themePreference;

  void setTheme(ThemePreference theme) =>
      _settingsRepository.setThemePreference(theme);

  // Budgeting ---------------------------------------------------------------

  int get payday => _settingsRepository.payday;

  /// e.g. '25th of the month', or '1st (calendar months)'.
  String get paydayLabel =>
      payday == 1 ? '1st (calendar months)' : '${ordinal(payday)} of the month';

  void setPayday(int day) => _settingsRepository.setPayday(day);

  int get budgetAlertPercent => _settingsRepository.budgetAlertPercent;

  List<int> get budgetAlertChoices => SettingsRepository.budgetAlertChoices;

  void setBudgetAlertPercent(int percent) =>
      _settingsRepository.setBudgetAlertPercent(percent);

  // Adding expenses ---------------------------------------------------------

  List<Wallet> get wallets => _wallets;

  /// The wallet new transactions start with: the chosen one if it still
  /// exists, otherwise the first wallet.
  String? get defaultWalletId {
    final chosen = _settingsRepository.defaultWalletId;
    if (_wallets.any((w) => w.id == chosen)) return chosen;
    return _wallets.isEmpty ? null : _wallets.first.id;
  }

  void setDefaultWallet(Wallet wallet) =>
      _settingsRepository.setDefaultWalletId(wallet.id);

  // Home --------------------------------------------------------------------

  bool get showHabitsOnHome => _settingsRepository.showHabitsOnHome;

  void setShowHabitsOnHome(bool show) =>
      _settingsRepository.setShowHabitsOnHome(show);

  bool get hideAmountsOnHome => _settingsRepository.hideAmountsOnHome;

  void setHideAmountsOnHome(bool hide) =>
      _settingsRepository.setHideAmountsOnHome(hide);

  // Privacy -------------------------------------------------------------------

  bool get privacyScreen => _settingsRepository.privacyScreen;

  void setPrivacyScreen(bool enabled) =>
      _settingsRepository.setPrivacyScreen(enabled);

  bool get appLock => _settingsRepository.appLock;

  /// Whether this phone has a screen lock to unlock the app with.
  bool get appLockAvailable => _appLockAvailable;

  /// Why turning the lock on didn't work, or null.
  String? get appLockMessage => _appLockMessage;

  Future<void> _loadAppLockAvailable() async {
    _appLockAvailable = await _appLockRepository.isAvailable();
    _notify();
  }

  Future<Result<void>> _setAppLock(bool enabled) async {
    _appLockMessage = null;
    if (enabled) {
      final confirmed = await _appLockRepository.confirm();
      if (confirmed case Error(:final error)) {
        _appLockMessage = switch (error) {
          AppLockException(problem: AppLockProblem.cancelled) => null,
          AppLockException(problem: AppLockProblem.noScreenLock) =>
            'Set a screen lock on this phone first',
          AppLockException(problem: AppLockProblem.lockedOut) =>
            'Too many tries. Wait a moment, then try again.',
          _ => "Couldn't check it's you. Please try again.",
        };
        _notify();
        return Result.error(error);
      }
    }
    return _settingsRepository.setAppLock(enabled);
  }

  // -------------------------------------------------------------------------

  void _onWalletsChanged() {
    if (!_disposed) loadWallets.execute();
  }

  Future<Result<void>> _loadWallets() async {
    final result = await _walletRepository.getWallets();
    switch (result) {
      case Ok(:final value):
        _wallets = value;
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settingsRepository.removeListener(_notify);
    _walletRepository.removeListener(_onWalletsChanged);
    loadWallets.dispose();
    setAppLock.dispose();
    super.dispose();
  }
}
