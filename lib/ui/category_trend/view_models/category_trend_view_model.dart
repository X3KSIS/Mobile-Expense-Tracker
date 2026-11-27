import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/category_trend.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

/// State for one category's page: its spending over the last [length]
/// months, how the selected month compares with a usual one, and where
/// the money went. Reloads when transactions change.
class CategoryTrendViewModel extends ChangeNotifier {
  CategoryTrendViewModel({
    required this._transactionRepository,
    required this.categoryName,
    DateTime? month,
    DateTime Function()? clock,
    this.length = 6,
  }) : _clock = clock ?? DateTime.now {
    _month = _clamp(monthOf(month ?? _clock()));
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_deleteTransaction);
    undoDelete = Command0<void>(_undoDelete);
  }

  final TransactionRepository _transactionRepository;
  final DateTime Function() _clock;

  final String categoryName;

  /// Months shown in the chart, ending with the current month.
  final int length;

  late final Command0<void> load;

  /// Deletes a transaction by id.
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

  List<Transaction> _all = const [];
  late DateTime _month;
  bool _loaded = false;
  bool _disposed = false;

  DateTime get now => _clock();

  /// First day of the month being looked at.
  DateTime get month => _month;

  /// The trend, or null when the category has no spending in the window.
  CategoryTrend? get trend => CategoryTrends.compute(
    transactions: _all,
    categoryName: categoryName,
    month: _month,
    now: _clock(),
    length: length,
  );

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  bool get isEmpty => _loaded && trend == null;

  void selectMonth(DateTime month) {
    final m = _clamp(monthOf(month));
    if (m == _month) return;
    _month = m;
    _notify();
  }

  DateTime _clamp(DateTime m) {
    final current = monthOf(_clock());
    final first = DateTime(current.year, current.month - length + 1);
    if (m.isAfter(current)) return current;
    if (m.isBefore(first)) return first;
    return m;
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
    undoDelete.dispose();
    super.dispose();
  }
}
