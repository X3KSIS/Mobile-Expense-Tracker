import 'package:flutter/foundation.dart';

import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_csv.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// How far back to export.
enum ExportPeriod {
  thisMonth('This month'),
  threeMonths('Last 3 months'),
  all('All time');

  const ExportPeriod(this.label);

  final String label;
}

/// State for Export data: the chosen period, what it covers, and the CSV.
class ExportViewModel extends ChangeNotifier {
  ExportViewModel({
    required this._transactionRepository,
    required this._walletRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    load = Command0<void>(_load)..execute();
  }

  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;

  List<Transaction> _all = const [];
  Map<String, String> _walletNames = const {};
  ExportPeriod _period = ExportPeriod.thisMonth;
  bool _loaded = false;
  bool _disposed = false;

  ExportPeriod get period => _period;

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// The transactions in [period].
  List<Transaction> get selected {
    final now = _clock();
    final from = switch (_period) {
      ExportPeriod.thisMonth => DateTime(now.year, now.month),
      ExportPeriod.threeMonths => DateTime(now.year, now.month - 2),
      ExportPeriod.all => null,
    };
    return [
      for (final t in _all)
        if (from == null || !t.date.isBefore(from)) t,
    ];
  }

  double get moneyOut =>
      selected.where((t) => !t.isIncome).fold(0, (a, t) => a + t.amount);

  double get moneyIn =>
      selected.where((t) => t.isIncome).fold(0, (a, t) => a + t.amount);

  /// The file name, e.g. `transactions-2026-11-28.csv`.
  String get fileName {
    final d = _clock();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'transactions-${d.year}-${two(d.month)}-${two(d.day)}.csv';
  }

  /// The CSV for [period].
  String buildCsv() =>
      TransactionCsv.build(selected, walletNames: _walletNames);

  void selectPeriod(ExportPeriod period) {
    if (period == _period) return;
    _period = period;
    _notify();
  }

  Future<Result<void>> _load() async {
    final (transactions, wallets) = await (
      _transactionRepository.getTransactions(),
      _walletRepository.getWallets(),
    ).wait;
    if (wallets case Ok(:final value)) {
      _walletNames = {for (final w in value) w.id: w.name};
    }
    switch (transactions) {
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
    load.dispose();
    super.dispose();
  }
}
