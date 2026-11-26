import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../activity/view_models/activity_view_model.dart';

/// One month of history: its days, newest first.
class HistoryMonth {
  const HistoryMonth({required this.month, required this.days});

  /// The 1st of the month.
  final DateTime month;
  final List<ActivityDay> days;

  Iterable<Transaction> get transactions => days.expand((d) => d.transactions);
}

/// State for the History page: every transaction, grouped by month and
/// day, filterable by type, with each month's totals. Reloads when
/// transactions change.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this._transactionRepository}) {
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_transactionRepository.deleteTransaction);
  }

  final TransactionRepository _transactionRepository;

  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  List<Transaction> _all = const [];
  List<HistoryMonth> _months = const [];
  ActivityFilter _filter = ActivityFilter.all;
  bool _loaded = false;
  bool _disposed = false;

  ActivityFilter get filter => _filter;

  /// Every month with transactions, newest first, whatever the filter.
  /// Rows the filter rejects fold away in place.
  List<HistoryMonth> get months => _months;

  bool isVisible(Transaction transaction) => _filter.matches(transaction);

  /// Matching transactions across the whole history.
  int get visibleCount => _all.where(isVisible).length;

  /// Money in among [month]'s matching transactions.
  double incomeIn(HistoryMonth month) => month.transactions
      .where((t) => t.isIncome && isVisible(t))
      .fold(0, (sum, t) => sum + t.amount);

  /// Money out among [month]'s matching transactions.
  double expensesIn(HistoryMonth month) => month.transactions
      .where((t) => !t.isIncome && isVisible(t))
      .fold(0, (sum, t) => sum + t.amount);

  /// Whether any of [month]'s transactions match the filter.
  bool hasVisible(HistoryMonth month) => month.transactions.any(isVisible);

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  bool get isEmpty => _loaded && _all.isEmpty;

  bool get hasNoMatches => _loaded && _all.isNotEmpty && visibleCount == 0;

  void setFilter(ActivityFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _notify();
  }

  void _onTransactionsChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _transactionRepository.getTransactions();
    switch (result) {
      case Ok(:final value):
        _all = value;
        final byMonth = <DateTime, List<Transaction>>{};
        for (final t in value) {
          byMonth
              .putIfAbsent(DateTime(t.date.year, t.date.month), () => [])
              .add(t);
        }
        _months = [
          for (final entry in byMonth.entries)
            HistoryMonth(
              month: entry.key,
              days: ActivityDay.group(entry.value),
            ),
        ]..sort((a, b) => b.month.compareTo(a.month));
        _loaded = true;
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _transactionRepository.removeListener(_onTransactionsChanged);
    load.dispose();
    delete.dispose();
    super.dispose();
  }
}
