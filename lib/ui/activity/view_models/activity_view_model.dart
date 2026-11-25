import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

/// Which transactions the Activity list shows.
enum ActivityFilter { all, expenses, income }

/// Transactions from one day.
class ActivityDay {
  const ActivityDay({required this.day, required this.transactions});

  /// Midnight of the day.
  final DateTime day;

  /// Newest first.
  final List<Transaction> transactions;

  /// Income minus expenses for the day.
  double get net => transactions.fold(0, (sum, t) => sum + t.signedAmount);
}

/// State for the Activity tab: every transaction, searchable, filterable
/// and grouped by day. Reloads when transactions change.
class ActivityViewModel extends ChangeNotifier {
  ActivityViewModel({required this._transactionRepository}) {
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_transactionRepository.deleteTransaction);
  }

  final TransactionRepository _transactionRepository;

  late final Command0<void> load;

  /// Deletes the transaction with the given id.
  late final Command1<void, String> delete;

  List<Transaction> _all = const [];
  List<Transaction> _visible = const [];
  List<ActivityDay> _days = const [];
  ActivityFilter _filter = ActivityFilter.all;
  String _query = '';
  bool _loaded = false;
  bool _disposed = false;

  ActivityFilter get filter => _filter;

  String get query => _query;

  /// Transactions matching the filter and search, grouped by day.
  List<ActivityDay> get days => _days;

  /// Number of transactions matching the filter and search.
  int get visibleCount => _visible.length;

  /// Total income among the visible transactions.
  double get totalIn =>
      _visible.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);

  /// Total expenses among the visible transactions.
  double get totalOut =>
      _visible.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// True when there are no transactions at all (not just no matches).
  bool get isEmpty => _loaded && _all.isEmpty;

  void setFilter(ActivityFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _rebuild();
  }

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    _rebuild();
  }

  void _onTransactionsChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _transactionRepository.getTransactions();
    switch (result) {
      case Ok(:final value):
        _all = value;
        _loaded = true;
        _rebuild();
        return const Result.ok(null);
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
  }

  void _rebuild() {
    final needle = _query.trim().toLowerCase();
    _visible = _all
        .where(
          (t) => switch (_filter) {
            ActivityFilter.all => true,
            ActivityFilter.expenses => !t.isIncome,
            ActivityFilter.income => t.isIncome,
          },
        )
        .where(
          (t) =>
              needle.isEmpty ||
              t.title.toLowerCase().contains(needle) ||
              t.categoryName.toLowerCase().contains(needle) ||
              (t.note?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);

    final groups = <DateTime, List<Transaction>>{};
    for (final t in _visible) {
      groups.putIfAbsent(dateOnly(t.date), () => []).add(t);
    }
    _days = [
      for (final entry in groups.entries)
        ActivityDay(
          day: entry.key,
          transactions: List.unmodifiable(entry.value),
        ),
    ]..sort((a, b) => b.day.compareTo(a.day));
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
