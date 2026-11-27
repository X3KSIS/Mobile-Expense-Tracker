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

  /// Budgets at or above this percentage of their limit show a warning
  /// (one of [budgetAlertChoices]).
  int get budgetAlertPercent;

  Future<Result<void>> setBudgetAlertPercent(int percent);

  /// The wallet Add transaction picks first, or null for the first wallet.
  String? get defaultWalletId;

  Future<Result<void>> setDefaultWalletId(String? walletId);

  /// Whether Home shows the spending habit card.
  bool get showHabitsOnHome;

  Future<Result<void>> setShowHabitsOnHome(bool show);

  /// Whether Home hides money amounts.
  bool get hideAmountsOnHome;

  Future<Result<void>> setHideAmountsOnHome(bool hide);

  /// Whether the app hides its content in recent apps and blocks
  /// screenshots (Android).
  bool get privacyScreen;

  Future<Result<void>> setPrivacyScreen(bool enabled);

  /// The warning levels offered.
  static const List<int> budgetAlertChoices = [70, 80, 90];
}
