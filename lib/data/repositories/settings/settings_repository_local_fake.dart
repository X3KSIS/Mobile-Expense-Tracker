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
  bool _privacyScreen = false;
  bool _appLock = false;
  bool _dailyReminder = false;
  int _reminderMinutes = SettingsRepository.defaultReminderMinutes;
  bool _billReminders = false;
  bool _budgetAlerts = true;
  DateTime? _notificationsSeenAt;

  @override
  bool get dailyReminder => _dailyReminder;

  @override
  Future<Result<void>> setDailyReminder(bool enabled) async {
    if (enabled != _dailyReminder) {
      _dailyReminder = enabled;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  int get reminderMinutes => _reminderMinutes;

  @override
  Future<Result<void>> setReminderMinutes(int minutes) async {
    if (minutes < 0 || minutes >= 24 * 60) {
      return Result.error(Exception('Reminder time must be within the day'));
    }
    if (minutes != _reminderMinutes) {
      _reminderMinutes = minutes;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  bool get billReminders => _billReminders;

  @override
  Future<Result<void>> setBillReminders(bool enabled) async {
    if (enabled != _billReminders) {
      _billReminders = enabled;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  bool get budgetAlerts => _budgetAlerts;

  @override
  Future<Result<void>> setBudgetAlerts(bool enabled) async {
    if (enabled != _budgetAlerts) {
      _budgetAlerts = enabled;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  DateTime? get notificationsSeenAt => _notificationsSeenAt;

  @override
  Future<Result<void>> markNotificationsSeen(DateTime at) async {
    final seen = _notificationsSeenAt;
    if (seen == null || at.isAfter(seen)) {
      _notificationsSeenAt = at;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  bool get appLock => _appLock;

  @override
  Future<Result<void>> setAppLock(bool enabled) async {
    if (enabled != _appLock) {
      _appLock = enabled;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  bool get privacyScreen => _privacyScreen;

  @override
  Future<Result<void>> setPrivacyScreen(bool enabled) async {
    if (enabled != _privacyScreen) {
      _privacyScreen = enabled;
      notifyListeners();
    }
    return const Result.ok(null);
  }

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
