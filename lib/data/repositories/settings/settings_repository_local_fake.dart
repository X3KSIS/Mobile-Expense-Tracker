import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';
import 'settings_repository.dart';

/// In-memory [SettingsRepository]. Settings reset on every launch until
/// local storage (Drift) is added.
class SettingsRepositoryLocalFake extends SettingsRepository {
  SettingsRepositoryLocalFake({this._themePreference = ThemePreference.system});

  ThemePreference _themePreference;

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
}
