import 'package:flutter/foundation.dart';

import '../../../data/repositories/budget/budget_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/budget_alert.dart';
import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the Home dashboard: monthly summary, top budget alert and the
/// most recent transactions.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._transactionRepository,
    required this._budgetRepository,
    this.recentLimit = 5,
  }) {
    load = Command0<void>(_load)..execute();
  }

  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;

  /// How many recent transactions to show.
  final int recentLimit;

  /// Loads (or reloads) everything on the dashboard.
  late final Command0<void> load;

  // TODO(auth): read the name from the signed-in user's profile.
  final String userName = 'Paul Mubanga';

  MonthlySummary? _summary;
  BudgetAlert? _budgetAlert;
  List<Transaction> _recentTransactions = const [];
  bool _hideAmounts = false;
  bool _disposed = false;

  MonthlySummary? get summary => _summary;

  /// The budget closest to its limit, or null when none needs attention.
  BudgetAlert? get budgetAlert => _budgetAlert;

  List<Transaction> get recentTransactions => _recentTransactions;

  /// Whether balance amounts are masked.
  bool get hideAmounts => _hideAmounts;

  /// True on the first load, before any data is available.
  bool get isLoading => load.running && !hasData;

  /// True when the last load failed.
  bool get hasError => load.error;

  /// True once data has loaded at least once.
  bool get hasData => _summary != null;

  /// Up to two initials from [userName], e.g. "PM".
  String get userInitials => userName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  void toggleHideAmounts() {
    _hideAmounts = !_hideAmounts;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    try {
      final results = await (
        _transactionRepository.getMonthlySummary(),
        _budgetRepository.getTopAlert(),
        _transactionRepository.getRecentTransactions(limit: recentLimit),
      ).wait;

      switch (results) {
        case (
          Ok(value: final summary),
          Ok(value: final alert),
          Ok(value: final recent),
        ):
          _summary = summary;
          _budgetAlert = alert;
          _recentTransactions = recent;
          return const Result.ok(null);
        case (Error(:final error), _, _) ||
            (_, Error(:final error), _) ||
            (_, _, Error(:final error)):
          return Result.error(error);
      }
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    load.dispose();
    super.dispose();
  }
}
