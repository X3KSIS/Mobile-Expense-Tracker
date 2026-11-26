import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';
import 'settings_repository.dart';

/// In-memory [SettingsRepository]. Settings reset on every launch until
/// local storage (Drift) is added.
class SettingsRepositoryLocalFake extends SettingsRepository {
  SettingsRepositoryLocalFake({
    this._themePreference = ThemePreference.system,
    this._payday = 1,
  });

  ThemePreference _themePreference;
  int _payday;

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
