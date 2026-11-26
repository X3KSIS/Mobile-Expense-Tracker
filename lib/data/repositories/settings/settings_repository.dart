import 'package:flutter/foundation.dart';

import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';

/// Source of truth for app settings: the colour theme and payday.
///
/// Extends [ChangeNotifier] and notifies whenever a setting changes, so the
/// app can rebuild with the new theme straight away.
abstract class SettingsRepository extends ChangeNotifier {
  ThemePreference get themePreference;

  Future<Result<void>> setThemePreference(ThemePreference preference);

  /// Day of the month pay arrives, 1–28. Budgets and the Home forecast run
  /// from one payday to the next; 1 means calendar months.
  int get payday;

  Future<Result<void>> setPayday(int day);
}
