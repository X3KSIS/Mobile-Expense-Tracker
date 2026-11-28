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

  /// Whether opening the app asks for the fingerprint, face or the phone's
  /// screen lock (see AppLockRepository).
  bool get appLock;

  Future<Result<void>> setAppLock(bool enabled);

  /// Whether the phone reminds the user each evening to record spending.
  bool get dailyReminder;

  Future<Result<void>> setDailyReminder(bool enabled);

  /// When the daily reminder comes, in minutes after midnight.
  int get reminderMinutes;

  Future<Result<void>> setReminderMinutes(int minutes);

  /// Whether the phone reminds the user the evening before a regular
  /// payment is due.
  bool get billReminders;

  Future<Result<void>> setBillReminders(bool enabled);

  /// When bill reminders come (a week before, 3 days before, on the day
  /// and every morning while overdue), in minutes after midnight.
  int get billReminderMinutes;

  Future<Result<void>> setBillReminderMinutes(int minutes);

  /// The bill reminder time when none was chosen: 8 am.
  static const int defaultBillReminderMinutes = 8 * 60;

  /// Whether budgets near or over their limit show in Notifications.
  bool get budgetAlerts;

  Future<Result<void>> setBudgetAlerts(bool enabled);

  /// When the user last opened Notifications; newer ones count as new.
  DateTime? get notificationsSeenAt;

  Future<Result<void>> markNotificationsSeen(DateTime at);

  /// The daily reminder's time when none was chosen: 8 pm.
  static const int defaultReminderMinutes = 20 * 60;

  /// The warning levels offered.
  static const List<int> budgetAlertChoices = [70, 80, 90];
}
