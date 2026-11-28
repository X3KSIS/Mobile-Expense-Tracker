import 'package:flutter/foundation.dart';

import '../../../data/repositories/budget/budget_repository.dart';
import '../../../data/repositories/detected_payment/detected_payment_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/app_notification.dart';
import '../../../domain/models/pay_cycle.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the Notifications page: what needs a look in the user's
/// spending, split into what's new since they last looked and earlier.
/// Opening the page counts as looking.
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required this._transactionRepository,
    required this._budgetRepository,
    required this._settingsRepository,
    required this._detectedPaymentRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _transactionRepository.addListener(_reload);
    _budgetRepository.addListener(_reload);
    _detectedPaymentRepository.addListener(_reload);
    load = Command0<void>(_load)..execute();
  }

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final SettingsRepository _settingsRepository;
  final DetectedPaymentRepository _detectedPaymentRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;

  List<AppNotification>? _items;

  /// When the user had last looked before opening the page this time;
  /// kept for the visit so "New" doesn't empty while they read it.
  DateTime? _seenBefore;
  bool _marked = false;
  bool _disposed = false;

  DateTime get now => _clock();

  bool get hasData => _items != null;

  bool get isLoading => load.running && !hasData;

  bool get isEmpty => _items?.isEmpty ?? true;

  /// New since the last visit, newest first.
  List<AppNotification> get fresh => [
    for (final n in _items ?? const <AppNotification>[])
      if (n.isNewSince(_seenBefore)) n,
  ];

  /// Seen on an earlier visit, newest first.
  List<AppNotification> get earlier => [
    for (final n in _items ?? const <AppNotification>[])
      if (!n.isNewSince(_seenBefore)) n,
  ];

  Future<Result<void>> _load() async {
    final (transactions, budgets) = await (
      _transactionRepository.getTransactions(),
      _budgetRepository.getBudgets(),
    ).wait;
    switch ((transactions, budgets)) {
      case (Ok(value: final all), Ok(value: final budgetList)):
        final now = _clock();
        final cycle = PayCycle.containing(now, _settingsRepository.payday);
        _items = SpendingNotifications.compute(
          budgets: budgetList,
          transactions: all,
          cycleStart: cycle.start,
          cycleEnd: cycle.end,
          alertAt: _settingsRepository.budgetAlertPercent / 100,
          toReview: _detectedPaymentRepository.pending,
          now: now,
          budgetAlerts: _settingsRepository.budgetAlerts,
        );
        if (!_marked) {
          _marked = true;
          _seenBefore = _settingsRepository.notificationsSeenAt;
          await _settingsRepository.markNotificationsSeen(now);
        }
        _notify();
        return const Result.ok(null);
      case (Error(:final error), _) || (_, Error(:final error)):
        _notify();
        return Result.error(error);
    }
  }

  void _reload() {
    if (!_disposed) load.execute();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _transactionRepository.removeListener(_reload);
    _budgetRepository.removeListener(_reload);
    _detectedPaymentRepository.removeListener(_reload);
    load.dispose();
    super.dispose();
  }
}
