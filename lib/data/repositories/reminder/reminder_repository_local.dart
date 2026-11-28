import 'dart:async';

import '../../../domain/models/bill.dart';
import '../../../domain/models/transaction.dart';
import '../../../routing/routes.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../services/local_notification_service.dart';
import '../bill/bill_repository.dart';
import '../settings/settings_repository.dart';
import '../transaction/transaction_repository.dart';
import 'reminder_repository.dart';

/// [ReminderRepository] scheduling notifications on the phone.
///
/// Everything is rescheduled whenever the settings, transactions or bills
/// change, and when the app starts:
///
/// * Daily reminder: one for each of the next [dailyDays] days at the
///   chosen time, skipping today once something was recorded today.
/// * Bill reminders: for each bill, a week before, 3 days before and on
///   the day, then every morning while it is overdue, at the bill
///   reminder time (see [BillReminders]).
class ReminderRepositoryLocal implements ReminderRepository {
  ReminderRepositoryLocal({
    required this._settings,
    required this._transactions,
    required this._bills,
    LocalNotificationService? service,
    DateTime Function()? clock,
    this.debounce = const Duration(milliseconds: 500),
  }) : _service = service ?? LocalNotificationService(),
       _clock = clock ?? DateTime.now;

  final SettingsRepository _settings;
  final TransactionRepository _transactions;
  final BillRepository _bills;
  final LocalNotificationService _service;
  final DateTime Function() _clock;

  /// Wait this long after a change before rescheduling, so a burst of
  /// changes reschedules once.
  final Duration debounce;

  static const int dailyDays = 7;
  static const int maxBills = 40;
  static const int _dailyId = 1;
  static const int _billId = 1000;

  /// Notification ids set aside for each bill.
  static const int _idsPerBill = 20;

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
    _bills.addListener(_scheduleSoon);
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
    final now = _clock();
    if (_settings.dailyReminder) {
      final result = await _transactions.getTransactions();
      if (result case Ok(:final value)) await _scheduleDaily(value, now);
    }
    if (_settings.billReminders) {
      final result = await _bills.getBills();
      if (result case Ok(:final value)) await _scheduleBills(value, now);
    }
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

  Future<void> _scheduleBills(List<Bill> bills, DateTime now) {
    final minutes = _settings.billReminderMinutes;
    return Future.wait([
      for (var i = 0; i < bills.length && i < maxBills; i++)
        for (final (slot, r) in BillReminders.times(
          bills[i],
          now,
          minutes,
        ).take(_idsPerBill).indexed)
          _service.schedule(
            id: _billId + i * _idsPerBill + slot,
            at: r.at,
            channel: ReminderChannel.bills,
            title: billReminderTitle(bills[i], r.daysLeft),
            body: billReminderBody(bills[i], r.daysLeft),
            payload: Routes.bills,
          ),
    ]);
  }

  /// e.g. "Rent is due in 3 days", "DStv is due today", "Rent is overdue".
  static String billReminderTitle(Bill bill, int daysLeft) =>
      switch (daysLeft) {
        < 0 => '${bill.name} is overdue',
        0 => '${bill.name} is due today',
        1 => '${bill.name} is due tomorrow',
        Bill.dueSoonDays => '${bill.name} is due in a week',
        _ => '${bill.name} is due in $daysLeft days',
      };

  static String billReminderBody(Bill bill, int daysLeft) {
    final amount = formatZmw(bill.amount);
    final due = formatDayMonth(bill.nextDue);
    if (daysLeft < 0) {
      final late = -daysLeft;
      return '$amount was due on $due ($late day${late == 1 ? '' : 's'} '
          'ago). Tap to mark it paid.';
    }
    if (daysLeft == 0) return '$amount. Tap to mark it paid.';
    return '$amount on $due.';
  }

  static DateTime _nextDay(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  @override
  void dispose() {
    _timer?.cancel();
    if (_started) {
      _settings.removeListener(_scheduleSoon);
      _transactions.removeListener(_scheduleSoon);
      _bills.removeListener(_scheduleSoon);
    }
  }
}
