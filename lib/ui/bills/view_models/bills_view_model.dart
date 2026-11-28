import 'package:flutter/foundation.dart';

import '../../../data/repositories/bill/bill_repository.dart';
import '../../../data/repositories/category/category_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/bill.dart';
import '../../../domain/models/recurring_payment.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/command.dart';
import '../../../utils/currency.dart';
import '../../../utils/result.dart';

/// What the bill form submits. [bill] is null when adding.
typedef BillInput = ({
  Bill? bill,
  String name,
  String amount,
  TransactionCategory? category,
  String? walletId,
  BillCadence cadence,
  DateTime nextDue,
});

/// A form to start from: a new bill filled in from a regular payment the
/// app spotted.
typedef BillDraft = ({
  String name,
  double amount,
  TransactionCategory? category,
  BillCadence cadence,
  DateTime nextDue,
});

/// State for the Bills page: overdue bills first, then those due within a
/// week, then the rest, with marking paid (which records the expense and
/// moves the bill to its next date), and suggestions from regular
/// payments found in the spending.
class BillsViewModel extends ChangeNotifier {
  BillsViewModel({
    required this._billRepository,
    required this._transactionRepository,
    required this._categoryRepository,
    required this._walletRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _billRepository.addListener(_reload);
    _transactionRepository.addListener(_reload);
    load = Command0<void>(_load)..execute();
    save = Command1<void, BillInput>(_save);
    delete = Command1<void, String>(_delete);
    markPaid = Command1<void, ({Bill bill, bool record})>(_markPaid);
  }

  final BillRepository _billRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final WalletRepository _walletRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, BillInput> save;
  late final Command1<void, String> delete;

  /// Marks a bill paid: records the expense when `record` is true, then
  /// moves the bill to its next due date.
  late final Command1<void, ({Bill bill, bool record})> markPaid;

  List<Bill> _bills = const [];
  List<Transaction> _transactions = const [];
  List<TransactionCategory> _categories = const [];
  List<Wallet> _wallets = const [];
  bool _loaded = false;
  bool _disposed = false;

  DateTime get now => _clock();

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  List<Bill> get bills => _bills;

  /// Past their due date and not marked paid, longest overdue first.
  List<Bill> get overdue => [
    for (final b in _bills)
      if (b.status(now) == BillStatus.overdue) b,
  ];

  /// Due today or within [Bill.dueSoonDays] days.
  List<Bill> get dueSoon => [
    for (final b in _bills)
      if (b.status(now) case BillStatus.dueToday || BillStatus.dueSoon) b,
  ];

  /// Due later than that.
  List<Bill> get later => [
    for (final b in _bills)
      if (b.status(now) == BillStatus.upcoming) b,
  ];

  double get overdueTotal => overdue.fold(0, (sum, b) => sum + b.amount);

  /// What the bills cost in an average month.
  double get monthlyTotal => _bills.fold(0, (sum, b) => sum + b.monthlyCost);

  /// Expense categories for the form.
  List<TransactionCategory> get categories => _categories;

  List<Wallet> get wallets => _wallets;

  /// Subscriptions and bills found in the spending (fixed amounts, weekly
  /// or monthly) that aren't bills here yet, as forms to start from.
  List<BillDraft> get suggestions {
    final names = {for (final b in _bills) b.name.trim().toLowerCase()};
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (final p in RecurringPayments.detect(_transactions, now))
        if (p.kind != RecurringKind.regular &&
            p.cadence != Cadence.fortnightly &&
            !names.contains(p.title.trim().toLowerCase()))
          _draftFrom(p, today),
    ];
  }

  BillDraft _draftFrom(RecurringPayment p, DateTime today) {
    final cadence = p.cadence == Cadence.weekly
        ? BillCadence.weekly
        : BillCadence.monthly;
    var due = p.nextDue;
    // A late one was probably paid and not recorded: start at the next.
    while (due.isBefore(today)) {
      due = cadence.next(due, p.nextDue.day);
    }
    return (
      name: p.title,
      amount: p.amount,
      category: _categories.where((c) => c.name == p.categoryName).firstOrNull,
      cadence: cadence,
      nextDue: due,
    );
  }

  String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter a name, e.g. Rent' : null;

  String? validateAmount(String? value) {
    final amount = parseAmount(value ?? '');
    if (amount == null) return 'Enter the amount';
    if (amount <= 0) return 'The amount must be more than zero';
    return null;
  }

  bool _reloadAgain = false;

  /// Reloads, or, when a load is already running (it may have read the
  /// data before this change), loads once more after it.
  void _reload() {
    if (_disposed) return;
    if (load.running) {
      _reloadAgain = true;
      return;
    }
    load.execute().then((_) {
      if (_reloadAgain && !_disposed) {
        _reloadAgain = false;
        _reload();
      }
    });
  }

  Future<Result<void>> _load() async {
    final (bills, transactions, categories, wallets) = await (
      _billRepository.getBills(),
      _transactionRepository.getTransactions(),
      _categoryRepository.getCategories(type: TransactionType.expense),
      _walletRepository.getWallets(),
    ).wait;
    switch (bills) {
      case Ok(:final value):
        _bills = value;
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
    if (transactions case Ok(:final value)) _transactions = value;
    if (categories case Ok(:final value)) _categories = value;
    if (wallets case Ok(:final value)) _wallets = value;
    _loaded = true;
    _notify();
    return const Result.ok(null);
  }

  Future<Result<void>> _save(BillInput input) async {
    final amount = parseAmount(input.amount);
    final existing = input.bill;
    final category =
        input.category ?? (existing == null ? null : _categoryOf(existing));
    if (amount == null || amount <= 0 || category == null) {
      return Result.error(Exception('Incomplete bill'));
    }
    final due = DateTime(
      input.nextDue.year,
      input.nextDue.month,
      input.nextDue.day,
    );
    final bill = Bill(
      id: input.bill?.id ?? '',
      name: input.name.trim(),
      amount: amount,
      categoryName: category.name,
      categoryIcon: category.icon,
      categoryColor: category.color,
      walletId:
          input.walletId ??
          (_wallets.isEmpty ? Transaction.defaultWalletId : _wallets.first.id),
      cadence: input.cadence,
      nextDue: due,
      anchorDay: due.day,
    );
    final result = await _billRepository.saveBill(bill);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  TransactionCategory _categoryOf(Bill bill) => TransactionCategory(
    id: 'bill-${bill.categoryName}',
    name: bill.categoryName,
    icon: bill.categoryIcon,
    color: bill.categoryColor,
    type: TransactionType.expense,
  );

  /// The category to show in the form for [bill]: the saved one, or one
  /// made from the bill's own details when it no longer exists.
  TransactionCategory categoryFor(Bill bill) =>
      _categories.where((c) => c.name == bill.categoryName).firstOrNull ??
      _categoryOf(bill);

  Future<Result<void>> _delete(String id) => _billRepository.deleteBill(id);

  Future<Result<void>> _markPaid(({Bill bill, bool record}) input) async {
    final bill = input.bill;
    if (input.record) {
      final added = await _transactionRepository.addTransaction(
        TransactionDraft(
          title: bill.name,
          amount: bill.amount,
          category: _categoryOf(bill),
          date: now,
          walletId: bill.walletId,
        ),
      );
      if (added case Error(:final error)) return Result.error(error);
    }
    final saved = await _billRepository.saveBill(bill.advanced());
    return switch (saved) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _billRepository.removeListener(_reload);
    _transactionRepository.removeListener(_reload);
    load.dispose();
    save.dispose();
    delete.dispose();
    markPaid.dispose();
    super.dispose();
  }
}
