import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

/// Which transactions a list shows.
enum ActivityFilter { all, expenses, income }

extension ActivityFilterMatch on ActivityFilter {
  /// Whether [transaction] passes this filter.
  bool matches(Transaction transaction) => switch (this) {
    ActivityFilter.all => true,
    ActivityFilter.expenses => !transaction.isIncome,
    ActivityFilter.income => transaction.isIncome,
  };
}

/// Transactions from one day.
class ActivityDay {
  const ActivityDay({required this.day, required this.transactions});

  /// Midnight of the day.
  final DateTime day;

  /// Newest first.
  final List<Transaction> transactions;

  /// Income minus expenses for the day.
  double get net => transactions.fold(0, (sum, t) => sum + t.signedAmount);

  /// Groups [transactions] by calendar day, newest day first.
  static List<ActivityDay> group(List<Transaction> transactions) {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      groups.putIfAbsent(dateOnly(t.date), () => []).add(t);
    }
    return [
      for (final entry in groups.entries)
        ActivityDay(
          day: entry.key,
          transactions: List.unmodifiable(entry.value),
        ),
    ]..sort((a, b) => b.day.compareTo(a.day));
  }
}

/// State for the Activity tab: the last [recentDays] days of transactions,
/// filterable and grouped by day, with a way into the full history.
/// Searching happens on its own full-screen page. Reloads when
/// transactions change.
class ActivityViewModel extends ChangeNotifier {
  ActivityViewModel({
    required this._transactionRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_transactionRepository.deleteTransaction);
  }

  /// How many days, counting today, the tab shows.
  static const int recentDays = 7;

  final TransactionRepository _transactionRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  int _totalCount = 0;
  List<Transaction> _recent = const [];
  List<Transaction> _visible = const [];
  List<ActivityDay> _days = const [];
  List<ActivityDay> _allDays = const [];
  ActivityFilter _filter = ActivityFilter.all;
  bool _loaded = false;
  bool _disposed = false;

  ActivityFilter get filter => _filter;

  /// Every recent transaction grouped by day, whatever the filter. The list
  /// shows these and folds away the ones [isVisible] rejects, so changing
  /// the filter animates row by row instead of swapping the whole list.
  List<ActivityDay> get allDays => _allDays;

  /// Whether [transaction] matches the current filter.
  bool isVisible(Transaction transaction) => _filter.matches(transaction);

  /// Recent transactions matching the filter, grouped by day.
  List<ActivityDay> get days => _days;

  /// Number of recent transactions matching the filter.
  int get visibleCount => _visible.length;

  /// Number of transactions in the full history.
  int get totalCount => _totalCount;

  /// Total income among the visible transactions.
  double get totalIn =>
      _visible.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);

  /// Total expenses among the visible transactions.
  double get totalOut =>
      _visible.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// True when there are no transactions at all (not just no recent ones).
  bool get isEmpty => _loaded && _totalCount == 0;

  /// True when there is history but nothing in the last [recentDays] days.
  bool get hasNoRecent => _loaded && _totalCount > 0 && _recent.isEmpty;

  /// True when there are recent transactions but none match the filter.
  bool get hasNoMatches => _loaded && _recent.isNotEmpty && _visible.isEmpty;

  void setFilter(ActivityFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _rebuild();
  }

  void _onTransactionsChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _transactionRepository.getTransactions();
    switch (result) {
      case Ok(:final value):
        final now = _clock();
        final today = DateTime(now.year, now.month, now.day);
        final since = DateTime(
          today.year,
          today.month,
          today.day - (recentDays - 1),
        );
        _totalCount = value.length;
        _recent = value
            .where((t) => !t.date.isBefore(since))
            .toList(growable: false);
        _allDays = ActivityDay.group(_recent);
        _loaded = true;
        _rebuild();
        return const Result.ok(null);
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
  }

  void _rebuild() {
    _visible = _recent.where(isVisible).toList(growable: false);
    _days = ActivityDay.group(_visible);
    _notify();
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
