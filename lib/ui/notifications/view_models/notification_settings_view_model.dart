import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/reminder/reminder_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for Notification settings: phone reminders (daily, bills) and
/// budget alerts in the app. Turning on a phone reminder asks the phone
/// for permission to show notifications first.
class NotificationSettingsViewModel extends ChangeNotifier {
  NotificationSettingsViewModel({
    required this._settingsRepository,
    required this._reminderRepository,
  }) {
    _settingsRepository.addListener(_notify);
    setDailyReminder = Command1<void, bool>(
      (on) => _setReminder(on, _settingsRepository.setDailyReminder),
    );
    setBillReminders = Command1<void, bool>(
      (on) => _setReminder(on, _settingsRepository.setBillReminders),
    );
    _checkAllowed();
  }

  final SettingsRepository _settingsRepository;
  final ReminderRepository _reminderRepository;

  late final Command1<void, bool> setDailyReminder;
  late final Command1<void, bool> setBillReminders;

  bool _allowed = true;
  String? _message;
  bool _disposed = false;

  static const String blockedMessage =
      'Notifications are off for Expense Tracker. Turn them on in your '
      "phone's settings.";

  bool get dailyReminder => _settingsRepository.dailyReminder;

  bool get billReminders => _settingsRepository.billReminders;

  bool get budgetAlerts => _settingsRepository.budgetAlerts;

  int get reminderMinutes => _settingsRepository.reminderMinutes;

  /// e.g. "20:00".
  String get reminderTimeLabel => DateFormat.Hm().format(
    DateTime(2000, 1, 1, reminderMinutes ~/ 60, reminderMinutes % 60),
  );

  /// Why a reminder can't be shown, e.g. the phone blocks notifications;
  /// null when all is well.
  String? get message =>
      _message ??
      ((dailyReminder || billReminders) && !_allowed ? blockedMessage : null);

  void setReminderTime(int hour, int minute) =>
      _settingsRepository.setReminderMinutes(hour * 60 + minute);

  void setBudgetAlerts(bool enabled) =>
      _settingsRepository.setBudgetAlerts(enabled);

  Future<void> _checkAllowed() async {
    _allowed = await _reminderRepository.notificationsAllowed();
    _notify();
  }

  Future<Result<void>> _setReminder(
    bool enabled,
    Future<Result<void>> Function(bool) save,
  ) async {
    _message = null;
    if (enabled) {
      _allowed =
          await _reminderRepository.notificationsAllowed() ||
          await _reminderRepository.requestPermission();
      if (!_allowed) {
        _message = blockedMessage;
        _notify();
        return Result.error(Exception('Notifications not allowed'));
      }
    }
    final result = await save(enabled);
    _notify();
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settingsRepository.removeListener(_notify);
    setDailyReminder.dispose();
    setBillReminders.dispose();
    super.dispose();
  }
}
