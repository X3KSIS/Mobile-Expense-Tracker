import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/recurring_payment.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the Regular payments page: subscriptions, bills and regular
/// spending found in the history, what they cost a month, and what is due
/// soon. Reloads when transactions change.
class RecurringViewModel extends ChangeNotifier {
  RecurringViewModel({
    required this._transactionRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _transactionRepository.addListener(_onTransactionsChanged);
    load = Command0<void>(_load)..execute();
  }

  final TransactionRepository _transactionRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;

  List<RecurringPayment> _payments = const [];
  bool _loaded = false;
  bool _disposed = false;

  DateTime get now => _clock();

  /// Every repeat payment, largest monthly cost first.
  List<RecurringPayment> get payments => _payments;

  /// Due within a few days, or late, soonest first.
  List<RecurringPayment> get dueSoon =>
      _payments.where((p) => p.status != RecurringStatus.upcoming).toList()
        ..sort((a, b) => a.nextDue.compareTo(b.nextDue));

  List<RecurringPayment> ofKind(RecurringKind kind) =>
      _payments.where((p) => p.kind == kind).toList(growable: false);

  double get monthlyTotal => RecurringPayments.monthlyTotal(_payments);

  double monthlyTotalOf(RecurringKind kind) =>
      RecurringPayments.monthlyTotal(ofKind(kind));

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  bool get isEmpty => _loaded && _payments.isEmpty;

  void _onTransactionsChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _transactionRepository.getTransactions();
    switch (result) {
      case Ok(:final value):
        _payments = RecurringPayments.detect(value, _clock());
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
    super.dispose();
  }
}
