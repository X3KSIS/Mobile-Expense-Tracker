import 'package:flutter/foundation.dart';

import '../../../domain/models/theme_preference.dart';
import '../../../utils/result.dart';

/// Source of truth for app settings, such as the colour theme.
///
/// Extends [ChangeNotifier] and notifies whenever a setting changes, so the
/// app can rebuild with the new theme straight away.
abstract class SettingsRepository extends ChangeNotifier {
  ThemePreference get themePreference;

  Future<Result<void>> setThemePreference(ThemePreference preference);
}
