import 'package:flutter/foundation.dart';

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
  }) {
    _settingsRepository.addListener(_notify);
    _walletRepository.addListener(_onWalletsChanged);
    loadWallets = Command0<void>(_loadWallets)..execute();
  }

  final SettingsRepository _settingsRepository;
  final WalletRepository _walletRepository;

  late final Command0<void> loadWallets;

  List<Wallet> _wallets = const [];
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
    super.dispose();
  }
}
