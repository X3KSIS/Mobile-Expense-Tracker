import 'package:flutter/foundation.dart';

import '../../../data/repositories/category/category_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/command.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';

typedef TransactionInput = ({String amount, String title, String note});

/// State for the Add transaction form: type, category, wallet, date and
/// saving.
class AddTransactionViewModel extends ChangeNotifier {
  AddTransactionViewModel({
    required this._transactionRepository,
    required this._categoryRepository,
    required this._walletRepository,
    TransactionType initialType = TransactionType.expense,
    this._initialCategoryId,
    DateTime Function()? clock,
  }) : _type = initialType,
       _clock = clock ?? DateTime.now {
    _date = _clock();
    loadCategories = Command0<void>(_loadCategories)..execute();
    save = Command1<void, TransactionInput>(_save);
  }

  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final WalletRepository _walletRepository;
  final String? _initialCategoryId;
  final DateTime Function() _clock;

  late final Command0<void> loadCategories;
  late final Command1<void, TransactionInput> save;

  TransactionType _type;
  List<TransactionCategory> _categories = const [];
  TransactionCategory? _selectedCategory;
  List<Wallet> _wallets = const [];
  String? _selectedWalletId;
  late DateTime _date;
  bool _disposed = false;

  TransactionType get type => _type;

  bool get isExpense => _type == TransactionType.expense;

  /// Categories for the selected [type].
  List<TransactionCategory> get categories =>
      _categories.where((c) => c.type == _type).toList(growable: false);

  TransactionCategory? get selectedCategory => _selectedCategory;

  DateTime get date => _date;

  /// Wallets to pay from or receive into.
  List<Wallet> get wallets => _wallets;

  /// The chosen wallet; the first wallet until the user picks one.
  String? get selectedWalletId => _selectedWalletId;

  /// Latest date the picker allows: today.
  DateTime get lastDate => _clock();

  /// Earliest date the picker allows.
  DateTime get firstDate => DateTime(_clock().year - 5);

  void selectType(TransactionType type) {
    if (type == _type) return;
    _type = type;
    _selectedCategory = _firstCategory();
    _notify();
  }

  void selectWallet(Wallet wallet) {
    _selectedWalletId = wallet.id;
    _notify();
  }

  void selectCategory(TransactionCategory category) {
    _selectedCategory = category;
    _notify();
  }

  /// Keeps the time of day when today is picked, so new entries sort
  /// above earlier ones; other days use midday.
  void selectDate(DateTime date) {
    final now = _clock();
    _date = dateOnly(date) == dateOnly(now)
        ? now
        : DateTime(date.year, date.month, date.day, 12);
    _notify();
  }

  /// Form validator for the amount field.
  String? validateAmount(String? value) {
    final amount = parseAmount(value ?? '');
    if (amount == null) return 'Enter an amount';
    if (amount <= 0) return 'Amount must be more than zero';
    if (amount > 10000000) return 'That amount looks too large';
    return null;
  }

  TransactionCategory? _firstCategory() {
    final list = categories;
    return list.isEmpty ? null : list.first;
  }

  /// Loads categories and wallets. Wallets are optional: without them the
  /// transaction goes to the default (cash) wallet.
  Future<Result<void>> _loadCategories() async {
    final (result, wallets) = await (
      _categoryRepository.getCategories(),
      _walletRepository.getWallets(),
    ).wait;
    if (wallets case Ok(:final value) when value.isNotEmpty) {
      _wallets = value;
      _selectedWalletId ??= value.first.id;
    }
    switch (result) {
      case Ok(:final value):
        _categories = value;
        final initial = value.where((c) => c.id == _initialCategoryId);
        if (initial.isNotEmpty) {
          _type = initial.first.type;
          _selectedCategory = initial.first;
        } else {
          _selectedCategory = _firstCategory();
        }
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _save(TransactionInput input) async {
    final amount = parseAmount(input.amount);
    final category = _selectedCategory;
    if (amount == null || amount <= 0 || category == null) {
      return Result.error(Exception('Incomplete transaction'));
    }
    final result = await _transactionRepository.addTransaction(
      TransactionDraft(
        title: input.title,
        amount: amount,
        category: category,
        date: _date,
        note: input.note,
        walletId: _selectedWalletId ?? Transaction.defaultWalletId,
      ),
    );
    return switch (result) {
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
    loadCategories.dispose();
    save.dispose();
    super.dispose();
  }
}
