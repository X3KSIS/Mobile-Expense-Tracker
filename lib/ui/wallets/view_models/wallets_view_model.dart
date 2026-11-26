import 'package:flutter/foundation.dart';

import '../../../data/repositories/category/category_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../domain/models/transfer.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/models/wallet_balances.dart';
import '../../../utils/command.dart';
import '../../../utils/currency.dart';
import '../../../utils/result.dart';

/// What the wallet sheet submits. [wallet] is null when adding.
typedef WalletInput = ({
  Wallet? wallet,
  String name,
  WalletKind kind,
  String openingBalance,
});

/// What the transfer sheet submits.
typedef TransferInput = ({
  String fromWalletId,
  String toWalletId,
  String amount,
  String fee,
  String note,
});

/// A transfer with its wallets' names, for the list.
typedef TransferEntry = ({Transfer transfer, String from, String to});

/// State for the Wallets page: each wallet's balance, the total, recent
/// transfers, and adding wallets and moving money between them. Reloads
/// when wallets or transactions change.
class WalletsViewModel extends ChangeNotifier {
  WalletsViewModel({
    required this._walletRepository,
    required this._transactionRepository,
    required this._categoryRepository,
    DateTime Function()? clock,
    this.recentTransferLimit = 6,
  }) : _clock = clock ?? DateTime.now {
    _walletRepository.addListener(_onDataChanged);
    _transactionRepository.addListener(_onDataChanged);
    load = Command0<void>(_load)..execute();
    saveWallet = Command1<void, WalletInput>(_saveWallet);
    transfer = Command1<void, TransferInput>(_transfer);
  }

  final WalletRepository _walletRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final DateTime Function() _clock;

  /// How many transfers the page lists.
  final int recentTransferLimit;

  late final Command0<void> load;
  late final Command1<void, WalletInput> saveWallet;
  late final Command1<void, TransferInput> transfer;

  /// The category charges are recorded under.
  static const String feesCategoryId = 'c-fees';

  List<WalletBalance> _balances = const [];
  List<TransferEntry> _transfers = const [];
  TransactionCategory? _feesCategory;
  bool _loaded = false;
  bool _disposed = false;

  List<WalletBalance> get balances => _balances;

  double get total => WalletBalance.total(_balances);

  List<Wallet> get wallets => [for (final b in _balances) b.wallet];

  /// The most recent transfers, newest first.
  List<TransferEntry> get recentTransfers => _transfers;

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// Moving money needs at least two wallets.
  bool get canTransfer => _balances.length >= 2;

  String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Give the wallet a name' : null;

  String? validateOpeningBalance(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return parseAmount(value!) == null ? 'Enter an amount' : null;
  }

  String? validateTransferAmount(String? value) {
    final amount = parseAmount(value ?? '');
    if (amount == null) return 'Enter an amount';
    if (amount <= 0) return 'Amount must be more than zero';
    return null;
  }

  String? validateFee(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final fee = parseAmount(value!);
    if (fee == null || fee < 0) return 'Enter the charge, or leave it blank';
    return null;
  }

  void _onDataChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final results = await (
      _walletRepository.getWallets(),
      _transactionRepository.getTransactions(),
      _walletRepository.getTransfers(),
      _categoryRepository.getCategories(type: TransactionType.expense),
    ).wait;
    switch (results) {
      case (
        Ok(value: final wallets),
        Ok(value: final transactions),
        Ok(value: final transfers),
        Ok(value: final categories),
      ):
        _balances = WalletBalance.compute(wallets, transactions, transfers);
        final names = {for (final w in wallets) w.id: w.name};
        _transfers = [
          for (final t in transfers.take(recentTransferLimit))
            (
              transfer: t,
              from: names[t.fromWalletId] ?? 'Removed wallet',
              to: names[t.toWalletId] ?? 'Removed wallet',
            ),
        ];
        _feesCategory = categories
            .where((c) => c.id == feesCategoryId)
            .firstOrNull;
        _loaded = true;
        _notify();
        return const Result.ok(null);
      case (Error(:final error), _, _, _) ||
          (_, Error(:final error), _, _) ||
          (_, _, Error(:final error), _) ||
          (_, _, _, Error(:final error)):
        _notify();
        return Result.error(error);
    }
  }

  Future<Result<void>> _saveWallet(WalletInput input) async {
    final name = input.name.trim();
    if (name.isEmpty) return Result.error(Exception('Missing name'));
    final opening = input.openingBalance.trim().isEmpty
        ? 0.0
        : parseAmount(input.openingBalance);
    if (opening == null) return Result.error(Exception('Invalid balance'));
    final wallet =
        input.wallet?.copyWith(
          name: name,
          kind: input.kind,
          openingBalance: opening,
        ) ??
        Wallet(id: '', name: name, kind: input.kind, openingBalance: opening);
    final result = await _walletRepository.saveWallet(wallet);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  /// Saves the transfer, then the charge (if any) as a Fees & charges
  /// expense from the sending wallet.
  Future<Result<void>> _transfer(TransferInput input) async {
    final amount = parseAmount(input.amount);
    final fee = input.fee.trim().isEmpty ? 0.0 : parseAmount(input.fee);
    if (amount == null || amount <= 0 || fee == null || fee < 0) {
      return Result.error(Exception('Invalid amount'));
    }
    if (input.fromWalletId == input.toWalletId) {
      return Result.error(Exception('Pick two different wallets'));
    }
    final now = _clock();
    final note = input.note.trim();
    final saved = await _walletRepository.addTransfer(
      Transfer(
        id: '',
        fromWalletId: input.fromWalletId,
        toWalletId: input.toWalletId,
        amount: amount,
        date: now,
        note: note.isEmpty ? null : note,
      ),
    );
    if (saved case Error(:final error)) return Result.error(error);

    final category = _feesCategory;
    if (fee > 0 && category != null) {
      final charged = await _transactionRepository.addTransaction(
        TransactionDraft(
          title: 'Transfer charge',
          amount: fee,
          category: category,
          date: now,
          walletId: input.fromWalletId,
        ),
      );
      if (charged case Error(:final error)) return Result.error(error);
    }
    return const Result.ok(null);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _walletRepository.removeListener(_onDataChanged);
    _transactionRepository.removeListener(_onDataChanged);
    load.dispose();
    saveWallet.dispose();
    transfer.dispose();
    super.dispose();
  }
}
