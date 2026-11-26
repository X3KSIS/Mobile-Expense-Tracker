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
    this.recentLimit = 5,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _authRepository.addListener(_onHeaderChanged);
    _settingsRepository.addListener(_onHeaderChanged);
    _detectedPaymentRepository.addListener(_onHeaderChanged);
    _transactionRepository.addListener(_onDataChanged);
    _budgetRepository.addListener(_onDataChanged);
    _walletRepository.addListener(_onDataChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_transactionRepository.deleteTransaction);
  }

  final DateTime Function() _clock;

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final WalletRepository _walletRepository;
  final DetectedPaymentRepository _detectedPaymentRepository;

  /// How many recent transactions to show.
  final int recentLimit;

  /// Loads (or reloads) everything on the dashboard.
  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  MonthlySummary? _summary;
  List<Budget> _budgets = const [];
  List<Transaction> _all = const [];
  List<Transaction> _recentTransactions = const [];
  List<WalletBalance> _wallets = const [];
  bool _hideAmounts = false;
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

  /// The budget closest to its limit this pay cycle, or null when none
  /// needs attention.
  BudgetAlert? get budgetAlert {
    final c = cycle;
    final progress = BudgetProgress.forPeriod(_budgets, _all, c.start, c.end);
    return BudgetProgress.topAlert(progress)?.toAlert();
  }

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

  /// Payments read from notifications, waiting to be added.
  int get detectedPaymentCount => _detectedPaymentRepository.pending.length;

  /// Each wallet with its balance.
  List<WalletBalance> get wallets => _wallets;

  /// Whether balance amounts are masked.
  bool get hideAmounts => _hideAmounts;

  /// True on the first load, before any data is available.
  bool get isLoading => load.running && !hasData;

  /// True when the last load failed.
  bool get hasError => load.error;

  /// True once data has loaded at least once.
  bool get hasData => _summary != null;

  /// The signed-in user's name, shown in the header.
  String get userName => _authRepository.currentUser?.name ?? '';

  /// Up to two initials from [userName], e.g. "PM".
  String get userInitials => _authRepository.currentUser?.initials ?? '';

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

  void _onDataChanged() {
    if (!_disposed) load.execute();
  }

  void toggleHideAmounts() {
    _hideAmounts = !_hideAmounts;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
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
    load.dispose();
    delete.dispose();
    super.dispose();
  }
}
