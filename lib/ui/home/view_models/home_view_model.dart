import '../../../domain/models/bill.dart';
import '../../../data/repositories/bill/bill_repository.dart';
import '../../../domain/models/cycle_spending.dart';
import '../../../domain/models/app_notification.dart';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/budget/budget_repository.dart';
import '../../../data/repositories/detected_payment/detected_payment_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/budget_alert.dart';
import '../../../domain/models/budget_progress.dart';
import '../../../domain/models/cycle_forecast.dart';
import '../../../domain/models/spending_insight.dart';
import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/theme_preference.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet_balances.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the Home dashboard: monthly summary, top budget alert and the
/// most recent transactions. Reloads when transactions or budgets change.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._transactionRepository,
    required this._budgetRepository,
    required this._authRepository,
    required this._settingsRepository,
    required this._walletRepository,
    required this._detectedPaymentRepository,
    this._billRepository,
    this.recentLimit = 5,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _authRepository.addListener(_onHeaderChanged);
    _settingsRepository.addListener(_onHeaderChanged);
    _detectedPaymentRepository.addListener(_onHeaderChanged);
    _transactionRepository.addListener(_onDataChanged);
    _budgetRepository.addListener(_onDataChanged);
    _walletRepository.addListener(_onDataChanged);
    _billRepository?.addListener(_onDataChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_deleteTransaction);
    undoDelete = Command0<void>(_undoDelete);
  }

  final DateTime Function() _clock;

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final WalletRepository _walletRepository;
  final DetectedPaymentRepository _detectedPaymentRepository;

  /// For the overdue bills banner; none without it.
  final BillRepository? _billRepository;

  List<Bill> _bills = const [];

  /// Bills past their due date and not marked paid.
  List<Bill> get overdueBills => [
    for (final b in _bills)
      if (b.status(_clock()) == BillStatus.overdue) b,
  ];

  double get overdueBillTotal =>
      overdueBills.fold(0, (sum, b) => sum + b.amount);

  /// How many recent transactions to show.
  final int recentLimit;

  /// Loads (or reloads) everything on the dashboard.
  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  /// Brings back the transaction [delete] removed last.
  late final Command0<void> undoDelete;

  String? _lastDeletedId;

  Future<Result<void>> _deleteTransaction(String id) {
    _lastDeletedId = id;
    return _transactionRepository.deleteTransaction(id);
  }

  Future<Result<void>> _undoDelete() async {
    final id = _lastDeletedId;
    if (id == null) return const Result.ok(null);
    _lastDeletedId = null;
    return _transactionRepository.restoreTransaction(id);
  }

  MonthlySummary? _summary;
  List<Budget> _budgets = const [];
  List<Transaction> _all = const [];
  List<Transaction> _recentTransactions = const [];
  List<WalletBalance> _wallets = const [];
  bool _disposed = false;

  MonthlySummary? get summary => _summary;

  /// The current pay cycle (a calendar month when payday is the 1st).
  PayCycle get cycle =>
      PayCycle.containing(_clock(), _settingsRepository.payday);

  /// Days to the next payday, counting today.
  int get daysToPayday => cycle.daysLeft(_clock());

  /// Day of the month pay arrives.
  int get payday => _settingsRepository.payday;

  void setPayday(int day) => _settingsRepository.setPayday(day);

  /// Now, by the view model's clock.
  DateTime get now => _clock();

  /// Spending this pay cycle: total, comparison, each day and where it
  /// went.
  CycleSpending get spending => CycleSpending.compute(
    transactions: _all,
    budgets: _budgets,
    cycle: cycle,
    now: _clock(),
    alertAt: _settingsRepository.budgetAlertPercent / 100,
  );

  /// The budget closest to its limit this pay cycle, or null when none
  /// needs attention.
  BudgetAlert? get budgetAlert {
    final c = cycle;
    final progress = BudgetProgress.forPeriod(
      _budgets,
      _all,
      c.start,
      c.end,
      alertAt: _settingsRepository.budgetAlertPercent / 100,
    );
    return BudgetProgress.topAlert(progress)?.toAlert();
  }

  /// The spending habit most worth knowing about this month, or null when
  /// there isn't enough spending to tell.
  SpendingInsight? get topInsight => SpendingInsights.compute(
    transactions: _all,
    month: _clock(),
    now: _clock(),
  ).firstOrNull;

  /// What can be spent each day until payday, and whether the money lasts.
  /// Null until wallets have loaded.
  CycleForecast? get forecast {
    if (_wallets.isEmpty) return null;
    return CycleForecast.compute(
      cycle: cycle,
      now: _clock(),
      balance: WalletBalance.total(_wallets),
      transactions: _all,
    );
  }

  List<Transaction> get recentTransactions => _recentTransactions;

  /// What needs a look in the user's spending (see Notifications).
  List<AppNotification> get notifications {
    final c = cycle;
    return SpendingNotifications.compute(
      budgets: _budgets,
      transactions: _all,
      cycleStart: c.start,
      cycleEnd: c.end,
      alertAt: _settingsRepository.budgetAlertPercent / 100,
      toReview: _detectedPaymentRepository.pending,
      now: _clock(),
      budgetAlerts: _settingsRepository.budgetAlerts,
      bills: _bills,
    );
  }

  /// Whether the bell shows its dot: something new since Notifications
  /// was last opened.
  bool get hasUnreadNotifications {
    final seenAt = _settingsRepository.notificationsSeenAt;
    return notifications.any((n) => n.isNewSince(seenAt));
  }

  /// Payments read from notifications, waiting to be added.
  int get detectedPaymentCount => _detectedPaymentRepository.pending.length;

  /// Each wallet with its balance.
  List<WalletBalance> get wallets => _wallets;

  /// Whether balance amounts are masked.
  bool get hideAmounts => _settingsRepository.hideAmountsOnHome;

  /// Whether to show the spending habit card (a preference).
  bool get showHabits => _settingsRepository.showHabitsOnHome;

  /// True on the first load, before any data is available.
  bool get isLoading => load.running && !hasData;

  /// True when the last load failed.
  bool get hasError => load.error;

  /// True once data has loaded at least once.
  bool get hasData => _summary != null;

  /// The signed-in user's name, shown in the header.
  String get userName => _authRepository.currentUser?.name ?? '';

  /// What to call the user in the greeting: their preferred name, or
  /// their first name.
  String get displayName => _authRepository.currentUser?.displayName ?? '';

  /// "Good morning" (5:00 to noon), "Good afternoon" (to 17:00) or "Good
  /// evening".
  String get greeting => greetingFor(_clock());

  static String greetingFor(DateTime time) => switch (time.hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Up to two initials from [userName], e.g. "PM".
  String get userInitials => _authRepository.currentUser?.initials ?? '';

  /// The profile photo, or null.
  Uint8List? get userPhoto => _authRepository.currentUser?.photo;

  /// The colour theme the user picked.
  ThemePreference get themePreference => _settingsRepository.themePreference;

  /// Switches to the dark theme, or to the light one when [dark] is false.
  void setDarkMode(bool dark) {
    _settingsRepository.setThemePreference(
      dark ? ThemePreference.dark : ThemePreference.light,
    );
  }

  /// Rebuilds the header when the profile or theme changes.
  void _onHeaderChanged() {
    if (!_disposed) notifyListeners();
  }

  bool _reloadAgain = false;

  /// Reloads, or, when a load is already running (it may have read the
  /// data before this change), loads once more after it.
  void _onDataChanged() {
    if (_disposed) return;
    if (load.running) {
      _reloadAgain = true;
      return;
    }
    load.execute().then((_) {
      if (_reloadAgain && !_disposed) {
        _reloadAgain = false;
        _onDataChanged();
      }
    });
  }

  /// Shows or hides amounts on Home; remembered as a preference.
  void toggleHideAmounts() =>
      _settingsRepository.setHideAmountsOnHome(!hideAmounts);

  Future<Result<void>> _load() async {
    final bills = await _billRepository?.getBills();
    if (bills case Ok(:final value)) _bills = value;
    try {
      final results = await (
        _transactionRepository.getMonthlySummary(),
        _budgetRepository.getBudgets(),
        _transactionRepository.getTransactions(),
        _transactionRepository.getRecentTransactions(limit: recentLimit),
        _walletRepository.getWallets(),
        _walletRepository.getTransfers(),
      ).wait;

      switch (results) {
        case (
          Ok(value: final summary),
          Ok(value: final budgets),
          Ok(value: final all),
          Ok(value: final recent),
          Ok(value: final wallets),
          Ok(value: final transfers),
        ):
          _summary = summary;
          _budgets = budgets;
          _all = all;
          _recentTransactions = recent;
          _wallets = WalletBalance.compute(wallets, all, transfers);
          return const Result.ok(null);
        case (Error(:final error), _, _, _, _, _) ||
            (_, Error(:final error), _, _, _, _) ||
            (_, _, Error(:final error), _, _, _) ||
            (_, _, _, Error(:final error), _, _) ||
            (_, _, _, _, Error(:final error), _) ||
            (_, _, _, _, _, Error(:final error)):
          return Result.error(error);
      }
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authRepository.removeListener(_onHeaderChanged);
    _settingsRepository.removeListener(_onHeaderChanged);
    _detectedPaymentRepository.removeListener(_onHeaderChanged);
    _transactionRepository.removeListener(_onDataChanged);
    _budgetRepository.removeListener(_onDataChanged);
    _walletRepository.removeListener(_onDataChanged);
    _billRepository?.removeListener(_onDataChanged);
    load.dispose();
    delete.dispose();
    undoDelete.dispose();
    super.dispose();
  }
}
