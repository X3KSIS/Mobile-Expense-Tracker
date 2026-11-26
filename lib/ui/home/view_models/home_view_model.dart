import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/budget/budget_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/budget_alert.dart';
import '../../../domain/models/budget_progress.dart';
import '../../../domain/models/monthly_summary.dart';
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
    this.recentLimit = 5,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _authRepository.addListener(_onHeaderChanged);
    _settingsRepository.addListener(_onHeaderChanged);
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

  /// How many recent transactions to show.
  final int recentLimit;

  /// Loads (or reloads) everything on the dashboard.
  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  MonthlySummary? _summary;
  BudgetAlert? _budgetAlert;
  List<Transaction> _recentTransactions = const [];
  List<WalletBalance> _wallets = const [];
  bool _hideAmounts = false;
  bool _disposed = false;

  MonthlySummary? get summary => _summary;

  /// The budget closest to its limit, or null when none needs attention.
  BudgetAlert? get budgetAlert => _budgetAlert;

  List<Transaction> get recentTransactions => _recentTransactions;

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
          final progress = BudgetProgress.forMonth(budgets, all, _clock());
          _summary = summary;
          _budgetAlert = BudgetProgress.topAlert(progress)?.toAlert();
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
    _transactionRepository.removeListener(_onDataChanged);
    _budgetRepository.removeListener(_onDataChanged);
    _walletRepository.removeListener(_onDataChanged);
    load.dispose();
    delete.dispose();
    super.dispose();
  }
}
