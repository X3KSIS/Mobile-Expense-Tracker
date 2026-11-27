import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';
import 'settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class SettingsRepositoryLocalFake extends SettingsRepository {
  SettingsRepositoryLocalFake({
    this._themePreference = ThemePreference.system,
    this._payday = 1,
  });

  ThemePreference _themePreference;
  int _payday;
  int _budgetAlertPercent = 80;
  String? _defaultWalletId;
  bool _showHabitsOnHome = true;
  bool _hideAmountsOnHome = false;

  @override
  bool get hideAmountsOnHome => _hideAmountsOnHome;

  @override
  Future<Result<void>> setHideAmountsOnHome(bool hide) async {
    if (hide != _hideAmountsOnHome) {
      _hideAmountsOnHome = hide;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  int get budgetAlertPercent => _budgetAlertPercent;

  @override
  Future<Result<void>> setBudgetAlertPercent(int percent) async {
    if (!SettingsRepository.budgetAlertChoices.contains(percent)) {
      return Result.error(Exception('Unsupported warning level'));
    }
    if (percent != _budgetAlertPercent) {
      _budgetAlertPercent = percent;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  String? get defaultWalletId => _defaultWalletId;

  @override
  Future<Result<void>> setDefaultWalletId(String? walletId) async {
    if (walletId != _defaultWalletId) {
      _defaultWalletId = walletId;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  bool get showHabitsOnHome => _showHabitsOnHome;

  @override
  Future<Result<void>> setShowHabitsOnHome(bool show) async {
    if (show != _showHabitsOnHome) {
      _showHabitsOnHome = show;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  ThemePreference get themePreference => _themePreference;

  @override
  Future<Result<void>> setThemePreference(ThemePreference preference) async {
    if (preference != _themePreference) {
      _themePreference = preference;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  int get payday => _payday;

  @override
  Future<Result<void>> setPayday(int day) async {
    if (day < 1 || day > PayCycle.maxPayday) {
      return Result.error(Exception('Payday must be 1 to 28'));
    }
    if (day != _payday) {
      _payday = day;
      notifyListeners();
    }
    return const Result.ok(null);
  }
}
