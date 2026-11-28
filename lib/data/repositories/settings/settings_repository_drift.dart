import 'dart:async';

import 'package:drift/drift.dart';

import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/privacy_screen_service.dart';
import 'settings_repository.dart';

/// [SettingsRepository] kept on the signed-in user's profile row, so the
/// theme and payday follow the account to every device.
///
/// Values are cached for the synchronous getters: call [load] before the
/// app starts.
class SettingsRepositoryDrift extends SettingsRepository {
  SettingsRepositoryDrift(
    this._db, {
    this._privacy = const PrivacyScreenService(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _updates = _db
        .tableUpdates(TableUpdateQuery.onTable(_db.profiles))
        .listen((_) => load());
  }

  final AppDatabase _db;
  final PrivacyScreenService _privacy;
  final DateTime Function() _clock;
  late final StreamSubscription<Set<TableUpdate>> _updates;

  ThemePreference _themePreference = ThemePreference.system;
  int _payday = 1;
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
  bool _disposed = false;

  /// Reads the stored values and notifies when they differ.
  Future<void> load() async {
    final row = await _db.select(_db.profiles).getSingleOrNull();
    if (row == null || _disposed) return;
    final theme = ThemePreference.values.asNameMap()[row.theme];
    final changed =
        (theme != null && theme != _themePreference) ||
        row.payday != _payday ||
        row.budgetAlertPercent != _budgetAlertPercent ||
        row.defaultWalletId != _defaultWalletId ||
        row.showHabits != _showHabitsOnHome ||
        row.hideAmounts != _hideAmountsOnHome ||
        row.privacyScreen != _privacyScreen ||
        row.appLock != _appLock ||
        row.dailyReminder != _dailyReminder ||
        row.reminderMinutes != _reminderMinutes ||
        row.billReminders != _billReminders ||
        row.budgetAlerts != _budgetAlerts ||
        !_sameMoment(row.notificationsSeenAt, _notificationsSeenAt);
    final privacyChanged = row.privacyScreen != _privacyScreen;
    if (theme != null) _themePreference = theme;
    _payday = row.payday;
    _budgetAlertPercent = row.budgetAlertPercent;
    _defaultWalletId = row.defaultWalletId;
    _showHabitsOnHome = row.showHabits;
    _hideAmountsOnHome = row.hideAmounts;
    _privacyScreen = row.privacyScreen;
    _appLock = row.appLock;
    _dailyReminder = row.dailyReminder;
    _reminderMinutes = row.reminderMinutes;
    _billReminders = row.billReminders;
    _budgetAlerts = row.budgetAlerts;
    _notificationsSeenAt = row.notificationsSeenAt;
    if (privacyChanged) await _privacy.setEnabled(_privacyScreen);
    if (changed) notifyListeners();
  }

  @override
  ThemePreference get themePreference => _themePreference;

  @override
  Future<Result<void>> setThemePreference(ThemePreference preference) =>
      guard(() async {
        if (preference == _themePreference) return;
        _themePreference = preference;
        notifyListeners();
        await _write(ProfilesCompanion(theme: Value(preference.name)));
      });

  @override
  int get payday => _payday;

  @override
  Future<Result<void>> setPayday(int day) => guard(() async {
    if (day < 1 || day > PayCycle.maxPayday) {
      throw Exception('Payday must be 1 to 28');
    }
    if (day == _payday) return;
    _payday = day;
    notifyListeners();
    await _write(ProfilesCompanion(payday: Value(day)));
  });

  @override
  int get budgetAlertPercent => _budgetAlertPercent;

  @override
  Future<Result<void>> setBudgetAlertPercent(int percent) => guard(() async {
    if (!SettingsRepository.budgetAlertChoices.contains(percent)) {
      throw Exception('Unsupported warning level');
    }
    if (percent == _budgetAlertPercent) return;
    _budgetAlertPercent = percent;
    notifyListeners();
    await _write(ProfilesCompanion(budgetAlertPercent: Value(percent)));
  });

  @override
  String? get defaultWalletId => _defaultWalletId;

  @override
  Future<Result<void>> setDefaultWalletId(String? walletId) => guard(() async {
    if (walletId == _defaultWalletId) return;
    _defaultWalletId = walletId;
    notifyListeners();
    await _write(ProfilesCompanion(defaultWalletId: Value(walletId)));
  });

  @override
  bool get showHabitsOnHome => _showHabitsOnHome;

  @override
  Future<Result<void>> setShowHabitsOnHome(bool show) => guard(() async {
    if (show == _showHabitsOnHome) return;
    _showHabitsOnHome = show;
    notifyListeners();
    await _write(ProfilesCompanion(showHabits: Value(show)));
  });

  @override
  bool get hideAmountsOnHome => _hideAmountsOnHome;

  @override
  Future<Result<void>> setHideAmountsOnHome(bool hide) => guard(() async {
    if (hide == _hideAmountsOnHome) return;
    _hideAmountsOnHome = hide;
    notifyListeners();
    await _write(ProfilesCompanion(hideAmounts: Value(hide)));
  });

  @override
  bool get privacyScreen => _privacyScreen;

  @override
  Future<Result<void>> setPrivacyScreen(bool enabled) => guard(() async {
    if (enabled == _privacyScreen) return;
    _privacyScreen = enabled;
    notifyListeners();
    await _privacy.setEnabled(enabled);
    await _write(ProfilesCompanion(privacyScreen: Value(enabled)));
  });

  @override
  bool get appLock => _appLock;

  @override
  Future<Result<void>> setAppLock(bool enabled) => guard(() async {
    if (enabled == _appLock) return;
    _appLock = enabled;
    notifyListeners();
    await _write(ProfilesCompanion(appLock: Value(enabled)));
  });

  @override
  bool get dailyReminder => _dailyReminder;

  @override
  Future<Result<void>> setDailyReminder(bool enabled) => guard(() async {
    if (enabled == _dailyReminder) return;
    _dailyReminder = enabled;
    notifyListeners();
    await _write(ProfilesCompanion(dailyReminder: Value(enabled)));
  });

  @override
  int get reminderMinutes => _reminderMinutes;

  @override
  Future<Result<void>> setReminderMinutes(int minutes) => guard(() async {
    if (minutes < 0 || minutes >= 24 * 60) {
      throw Exception('Reminder time must be within the day');
    }
    if (minutes == _reminderMinutes) return;
    _reminderMinutes = minutes;
    notifyListeners();
    await _write(ProfilesCompanion(reminderMinutes: Value(minutes)));
  });

  @override
  bool get billReminders => _billReminders;

  @override
  Future<Result<void>> setBillReminders(bool enabled) => guard(() async {
    if (enabled == _billReminders) return;
    _billReminders = enabled;
    notifyListeners();
    await _write(ProfilesCompanion(billReminders: Value(enabled)));
  });

  @override
  bool get budgetAlerts => _budgetAlerts;

  @override
  Future<Result<void>> setBudgetAlerts(bool enabled) => guard(() async {
    if (enabled == _budgetAlerts) return;
    _budgetAlerts = enabled;
    notifyListeners();
    await _write(ProfilesCompanion(budgetAlerts: Value(enabled)));
  });

  @override
  DateTime? get notificationsSeenAt => _notificationsSeenAt;

  @override
  Future<Result<void>> markNotificationsSeen(DateTime at) => guard(() async {
    final seen = _notificationsSeenAt;
    if (seen != null && !at.isAfter(seen)) return;
    _notificationsSeenAt = at;
    notifyListeners();
    await _write(ProfilesCompanion(notificationsSeenAt: Value(at)));
  });

  static bool _sameMoment(DateTime? a, DateTime? b) =>
      a == null ? b == null : b != null && a.isAtSameMomentAs(b);

  /// Saves [change] on the profile. Signed out, it goes on a local
  /// profile that the first account to sign in takes over.
  Future<void> _write(ProfilesCompanion change) async {
    final now = _clock();
    final updated = await _db
        .update(_db.profiles)
        .write(
          change.copyWith(modifiedAt: Value(now), dirty: const Value(true)),
        );
    if (updated > 0) return;
    await _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(
            userId: AppDatabase.localUserId,
            theme: Value(_themePreference.name),
            payday: Value(_payday),
            budgetAlertPercent: Value(_budgetAlertPercent),
            defaultWalletId: Value(_defaultWalletId),
            showHabits: Value(_showHabitsOnHome),
            hideAmounts: Value(_hideAmountsOnHome),
            privacyScreen: Value(_privacyScreen),
            appLock: Value(_appLock),
            dailyReminder: Value(_dailyReminder),
            reminderMinutes: Value(_reminderMinutes),
            billReminders: Value(_billReminders),
            budgetAlerts: Value(_budgetAlerts),
            notificationsSeenAt: Value(_notificationsSeenAt),
            createdAt: now,
            modifiedAt: now,
            dirty: const Value(true),
          ),
        );
  }

  @override
  void dispose() {
    _disposed = true;
    _updates.cancel();
    super.dispose();
  }
}
