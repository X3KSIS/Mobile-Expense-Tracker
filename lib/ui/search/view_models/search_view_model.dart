import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../activity/view_models/activity_view_model.dart';

/// State for the full-screen transaction search: the query, matches
/// grouped by day, and category suggestions to start from. Reloads when
/// transactions change.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required this._transactionRepository,
    this.maxSuggestions = 6,
  }) {
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
    delete = Command1<void, String>(_deleteTransaction);
    undoDelete = Command0<void>(_undoDelete);
  }

  final TransactionRepository _transactionRepository;

  /// How many category suggestions to offer before anything is typed.
  final int maxSuggestions;

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

  List<Transaction> _all = const [];
  List<ActivityDay> _results = const [];
  int _resultCount = 0;
  String _query = '';
  bool _loaded = false;
  bool _disposed = false;

  String get query => _query;

  /// True once something other than spaces has been typed.
  bool get hasQuery => _query.trim().isNotEmpty;

  /// Matches for [query], grouped by day, newest first.
  List<ActivityDay> get results => _results;

  int get resultCount => _resultCount;

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// The most used category names, most used first.
  List<String> get suggestions {
    final counts = <String, int>{};
    for (final t in _all) {
      counts.update(t.categoryName, (n) => n + 1, ifAbsent: () => 1);
    }
    final names = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return names.take(maxSuggestions).toList(growable: false);
  }

  /// Matches title, category and note, ignoring case and surrounding
  /// spaces.
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
    final matches = needle.isEmpty
        ? const <Transaction>[]
        : _all
              .where(
                (t) =>
                    t.title.toLowerCase().contains(needle) ||
                    t.categoryName.toLowerCase().contains(needle) ||
                    (t.note?.toLowerCase().contains(needle) ?? false),
              )
              .toList(growable: false);
    _resultCount = matches.length;
    _results = ActivityDay.group(matches);
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
    undoDelete.dispose();
    super.dispose();
  }
}
