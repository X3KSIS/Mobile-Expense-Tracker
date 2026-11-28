import 'dart:async';

import '../../../domain/models/recurring_payment.dart';
import '../../../domain/models/transaction.dart';
import '../../../routing/routes.dart';
import '../../../utils/currency.dart';
import '../../../utils/result.dart';
import '../../services/local_notification_service.dart';
import '../settings/settings_repository.dart';
import '../transaction/transaction_repository.dart';
import 'reminder_repository.dart';

/// [ReminderRepository] scheduling notifications on the phone.
///
/// Everything is rescheduled whenever the settings or transactions change:
///
/// * Daily reminder: one for each of the next [dailyDays] days at the
///   chosen time, skipping today once something was recorded today.
/// * Bill reminders: at [billHour] the evening before each regular
///   payment's next due date.
class ReminderRepositoryLocal implements ReminderRepository {
  ReminderRepositoryLocal({
    required this._settings,
    required this._transactions,
    LocalNotificationService? service,
    DateTime Function()? clock,
    this.debounce = const Duration(milliseconds: 500),
  }) : _service = service ?? LocalNotificationService(),
       _clock = clock ?? DateTime.now;

  final SettingsRepository _settings;
  final TransactionRepository _transactions;
  final LocalNotificationService _service;
  final DateTime Function() _clock;

  /// Wait this long after a change before rescheduling, so a burst of
  /// changes reschedules once.
  final Duration debounce;

  static const int dailyDays = 7;
  static const int billHour = 18;
  static const int maxBills = 20;
  static const int _dailyId = 1;
  static const int _billId = 100;

  Timer? _timer;
  bool _started = false;

  @override
  Future<bool> notificationsAllowed() => _service.areEnabled();

  @override
  Future<bool> requestPermission() => _service.requestPermission();

  @override
  Stream<String> get openRequests => _service.taps;

  @override
  Future<String?> launchRoute() => _service.launchPayload();

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _service.initialize();
    _settings.addListener(_scheduleSoon);
    _transactions.addListener(_scheduleSoon);
    await reschedule();
  }

  void _scheduleSoon() {
    _timer?.cancel();
    _timer = Timer(debounce, reschedule);
  }

  /// Replaces the scheduled reminders with ones for the current settings
  /// and transactions.
  Future<void> reschedule() async {
    await _service.cancelPending();
    final daily = _settings.dailyReminder;
    final bills = _settings.billReminders;
    if (!daily && !bills) return;
    final result = await _transactions.getTransactions();
    if (result case Error()) return;
    final transactions = (result as Ok<List<Transaction>>).value;
    final now = _clock();
    if (daily) await _scheduleDaily(transactions, now);
    if (bills) await _scheduleBills(transactions, now);
  }

  Future<void> _scheduleDaily(List<Transaction> transactions, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final recordedToday = transactions.any(
      (t) => !t.date.isBefore(today) && t.date.isBefore(_nextDay(today)),
    );
    final minutes = _settings.reminderMinutes;
    return Future.wait([
      for (var day = 0; day < dailyDays; day++)
        if (!(day == 0 && recordedToday))
          if (DateTime(today.year, today.month, today.day + day, 0, minutes)
              case final at when at.isAfter(now))
            _service.schedule(
              id: _dailyId + day,
              at: at,
              channel: ReminderChannel.daily,
              title: 'Anything spent today?',
              body: 'Add it now while you remember. It only takes a moment.',
              payload: Routes.add,
            ),
    ]);
  }

  Future<void> _scheduleBills(List<Transaction> transactions, DateTime now) {
    final payments = RecurringPayments.detect(
      transactions,
      now,
    ).where((p) => p.status != RecurringStatus.late).take(maxBills).toList();
    return Future.wait([
      for (var i = 0; i < payments.length; i++)
        if (_eveningBefore(payments[i].nextDue) case final at
            when at.isAfter(now))
          _service.schedule(
            id: _billId + i,
            at: at,
            channel: ReminderChannel.bills,
            title: '${payments[i].title} is due tomorrow',
            body: payments[i].fixedAmount
                ? 'It is usually ${formatZmw(payments[i].amount)}.'
                : 'It is usually about ${formatZmw(payments[i].amount)}.',
            payload: Routes.recurring,
          ),
    ]);
  }

  static DateTime _eveningBefore(DateTime due) =>
      DateTime(due.year, due.month, due.day - 1, billHour);

  static DateTime _nextDay(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  @override
  void dispose() {
    _timer?.cancel();
    if (_started) {
      _settings.removeListener(_scheduleSoon);
      _transactions.removeListener(_scheduleSoon);
    }
  }
}
