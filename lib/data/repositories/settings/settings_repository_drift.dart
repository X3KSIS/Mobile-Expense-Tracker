import 'dart:async';

import 'package:drift/drift.dart';

import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import 'settings_repository.dart';

/// [SettingsRepository] kept on the signed-in user's profile row, so the
/// theme and payday follow the account to every device.
///
/// Values are cached for the synchronous getters: call [load] before the
/// app starts.
class SettingsRepositoryDrift extends SettingsRepository {
  SettingsRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _updates = _db
        .tableUpdates(TableUpdateQuery.onTable(_db.profiles))
        .listen((_) => load());
  }

  final AppDatabase _db;
  final DateTime Function() _clock;
  late final StreamSubscription<Set<TableUpdate>> _updates;

  ThemePreference _themePreference = ThemePreference.system;
  int _payday = 1;
  int _budgetAlertPercent = 80;
  String? _defaultWalletId;
  bool _showHabitsOnHome = true;
  bool _hideAmountsOnHome = false;
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
        row.hideAmounts != _hideAmountsOnHome;
    if (theme != null) _themePreference = theme;
    _payday = row.payday;
    _budgetAlertPercent = row.budgetAlertPercent;
    _defaultWalletId = row.defaultWalletId;
    _showHabitsOnHome = row.showHabits;
    _hideAmountsOnHome = row.hideAmounts;
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
