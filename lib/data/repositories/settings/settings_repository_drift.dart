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
  bool _disposed = false;

  /// Reads the stored values and notifies when they differ.
  Future<void> load() async {
    final row = await _db.select(_db.profiles).getSingleOrNull();
    if (row == null || _disposed) return;
    final theme = ThemePreference.values.asNameMap()[row.theme];
    final payday = row.payday;
    final changed =
        (theme != null && theme != _themePreference) || payday != _payday;
    if (theme != null) _themePreference = theme;
    _payday = payday;
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
