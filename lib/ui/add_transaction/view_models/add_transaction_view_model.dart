import 'package:flutter/foundation.dart';

import '../../../data/repositories/category/category_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../data/repositories/wallet/wallet_repository.dart';
import '../../../domain/models/money_message.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/command.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../../utils/money_message_parser.dart';
import '../../../utils/result.dart';

typedef TransactionInput = ({String amount, String title, String note});

/// Route `extra` asking Add transaction to start from [transaction] (same
/// amount, category, wallet, title and note) as a new one dated now.
class RepeatTransaction {
  const RepeatTransaction(this.transaction);

  final Transaction transaction;
}

/// Something recorded again and again (the same place at least twice in
/// the last [AddTransactionViewModel.quickPickDays] days): one tap fills
/// the form with it.
typedef QuickPick = ({
  String title,
  TransactionCategory category,
  String walletId,
  double amount,

  /// Whether it always cost the same, so the amount can be filled too.
  bool fixedAmount,
});

/// The text fields filled from a message; the view puts them in its
/// controllers.
typedef MessagePrefill = ({String amount, String title, String note});

/// State for the transaction form: type, category, wallet, date and
/// saving. Adds a new transaction (from [repeat] when given), or edits
/// [editing].
class AddTransactionViewModel extends ChangeNotifier {
  AddTransactionViewModel({
    required this._transactionRepository,
    required this._categoryRepository,
    required this._walletRepository,
    TransactionType initialType = TransactionType.expense,
    this._initialCategoryId,
    this._initialMessage,
    this._defaultWalletId,
    Transaction? editing,
    Transaction? repeat,
    DateTime Function()? clock,
  }) : _editing = editing,
       _source = editing ?? repeat,
       _type = (editing ?? repeat)?.type ?? initialType,
       _clock = clock ?? DateTime.now {
    _date = editing?.date ?? _clock();
    final source = _source;
    if (source != null) {
      _initialMessage = null;
      _selectedWalletId = source.walletId;
      final amount = source.amount;
      _initialPrefill = (
        amount: amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2),
        title: source.title,
        note: source.note ?? '',
      );
    }
    loadCategories = Command0<void>(_loadCategories)..execute();
    save = Command1<void, TransactionInput>(_save);
  }

  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final WalletRepository _walletRepository;
  final String? _initialCategoryId;

  /// The wallet picked first for a new transaction (a preference).
  final String? _defaultWalletId;
  final Transaction? _editing;

  /// The transaction being edited or repeated, whose values fill the form.
  final Transaction? _source;
  final DateTime Function() _clock;

  late final Command0<void> loadCategories;
  late final Command1<void, TransactionInput> save;

  TransactionType _type;
  List<TransactionCategory> _categories = const [];
  TransactionCategory? _selectedCategory;
  List<Wallet> _wallets = const [];
  String? _selectedWalletId;
  double? _pendingFee;
  MoneyMessage? _initialMessage;
  MessagePrefill? _initialPrefill;
  late DateTime _date;
  List<Transaction> _history = const [];
  bool _disposed = false;

  /// How far back [quickPicks] look.
  static const int quickPickDays = 90;

  /// Whether to offer [quickPicks]: for a new transaction typed by hand,
  /// not when editing, repeating or filling from a message.
  bool get offersQuickPicks =>
      _source == null && _initialMessage == null && !_filledFromMessage;

  bool _filledFromMessage = false;

  /// Up to six places recorded at least twice lately for the selected
  /// type, most used first.
  List<QuickPick> get quickPicks {
    final now = _clock();
    final since = now.subtract(const Duration(days: quickPickDays));
    final groups = <String, List<Transaction>>{};
    for (final t in _history) {
      final key = t.title.trim().toLowerCase();
      if (key.isEmpty || t.type != _type) continue;
      if (t.date.isBefore(since) || t.date.isAfter(now)) continue;
      groups.putIfAbsent(key, () => []).add(t);
    }
    final picks = <(QuickPick, int, DateTime)>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;
      group.sort((a, b) => b.date.compareTo(a.date));
      final latest = group.first;
      final category = _categories
          .where((c) => c.type == _type && c.name == latest.categoryName)
          .firstOrNull;
      if (category == null) continue;
      picks.add((
        (
          title: latest.title.trim(),
          category: category,
          walletId: latest.walletId,
          amount: latest.amount,
          fixedAmount: group.every((t) => t.amount == latest.amount),
        ),
        group.length,
        latest.date,
      ));
    }
    picks.sort((a, b) {
      final byUses = b.$2.compareTo(a.$2);
      return byUses != 0 ? byUses : b.$3.compareTo(a.$3);
    });
    return [for (final p in picks.take(6)) p.$1];
  }

  /// Fills the category and wallet from [pick]. Returns the title, and
  /// the amount when it is always the same (otherwise null, so what the
  /// user typed stays).
  ({String title, String? amount}) applyQuickPick(QuickPick pick) {
    _selectedCategory = pick.category;
    if (_wallets.any((w) => w.id == pick.walletId)) {
      _selectedWalletId = pick.walletId;
    }
    _notify();
    final amount = pick.amount;
    return (
      title: pick.title,
      amount: pick.fixedAmount
          ? amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)
          : null,
    );
  }

  /// Picks today or yesterday (keeping the time rules of [selectDate]).
  void selectDaysAgo(int days) {
    final now = _clock();
    selectDate(DateTime(now.year, now.month, now.day - days));
  }

  /// 0 for today, 1 for yesterday, null for any other day.
  int? get daysAgo {
    final days = dateOnly(_clock()).difference(dateOnly(_date)).inDays;
    return days == 0 || days == 1 ? days : null;
  }

  TransactionType get type => _type;

  /// Whether this form edits an existing transaction.
  bool get isEditing => _editing != null;

  bool get isExpense => _type == TransactionType.expense;

  /// Categories for the selected [type].
  List<TransactionCategory> get categories =>
      _categories.where((c) => c.type == _type).toList(growable: false);

  TransactionCategory? get selectedCategory => _selectedCategory;

  DateTime get date => _date;

  /// Wallets to pay from or receive into.
  List<Wallet> get wallets => _wallets;

  /// A charge read from a message, saved as a separate Fees & charges
  /// expense alongside the transaction. Null when there is none.
  double? get pendingFee => _pendingFee;

  void dropPendingFee() {
    _pendingFee = null;
    _notify();
  }

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

  /// The text fields to fill from the message this form was opened with
  /// (e.g. a payment read from a notification), once. Null after that,
  /// or when there was none.
  MessagePrefill? takeInitialPrefill() {
    final prefill = _initialPrefill;
    _initialPrefill = null;
    return prefill;
  }

  /// Reads a mobile money or bank SMS; null when it isn't one.
  MoneyMessage? readMessage(String text) => MoneyMessageParser.parse(text);

  /// Fills the form from [message]: type, category, wallet, date and any
  /// charge. Returns the amount, title and note for the text fields.
  MessagePrefill applyMessage(MoneyMessage message) {
    _filledFromMessage = true;
    _type = message.isIncome ? TransactionType.income : TransactionType.expense;
    final options = categories;
    _selectedCategory =
        options.where((c) => c.name == message.categoryHint).firstOrNull ??
        options.where((c) => c.icon == 'other').firstOrNull ??
        _firstCategory();
    _selectedWalletId = _walletFor(message)?.id ?? _selectedWalletId;
    final date = message.date;
    if (date != null && !date.isAfter(_clock())) _date = date;
    _pendingFee = message.fee;
    _notify();

    final amount = message.amount;
    final provider = message.provider;
    final reference = message.reference;
    final balance = message.balance;
    return (
      amount: amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2),
      title: message.counterparty ?? _titleFromHint(message) ?? '',
      note: [
        ?provider,
        if (reference != null) 'Ref $reference',
        if (balance != null) 'Balance after ${formatZmw(balance)}',
      ].join(' · '),
    );
  }

  /// The wallet a message came from: one named after the provider (e.g.
  /// "MTN MoMo" for an MTN message), else the first of the same kind.
  Wallet? _walletFor(MoneyMessage message) {
    final provider = message.provider?.toLowerCase();
    if (provider != null) {
      final brand = provider.split(' ').first;
      final named = _wallets.where((w) => w.name.toLowerCase().contains(brand));
      if (named.isNotEmpty) return named.first;
    }
    final kind = message.providerKind;
    return kind == null
        ? null
        : _wallets.where((w) => w.kind == kind).firstOrNull;
  }

  static String? _titleFromHint(MoneyMessage message) =>
      message.categoryHint == 'Utilities' ? 'ZESCO units' : message.provider;

  void selectWallet(Wallet wallet) {
    _selectedWalletId = wallet.id;
    _notify();
  }

  void selectCategory(TransactionCategory category) {
    _selectedCategory = category;
    _notify();
  }

  /// Keeps the time of day when today is picked, so new entries sort
  /// above earlier ones, and keeps an edited transaction's own time on its
  /// own day; other days use midday.
  void selectDate(DateTime date) {
    final now = _clock();
    final original = _editing?.date;
    _date = original != null && dateOnly(date) == dateOnly(original)
        ? original
        : dateOnly(date) == dateOnly(now)
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
    final (result, wallets, history) = await (
      _categoryRepository.getCategories(),
      _walletRepository.getWallets(),
      _transactionRepository.getTransactions(),
    ).wait;
    if (history case Ok(:final value)) _history = value;
    if (wallets case Ok(:final value) when value.isNotEmpty) {
      _wallets = value;
      _selectedWalletId ??=
          value.where((w) => w.id == _defaultWalletId).firstOrNull?.id ??
          value.first.id;
    }
    switch (result) {
      case Ok(:final value):
        _categories = value;
        final initial = value.where((c) => c.id == _initialCategoryId);
        final source = _source;
        if (source != null) {
          _selectedCategory = _categoryOf(source);
        } else if (initial.isNotEmpty) {
          _type = initial.first.type;
          _selectedCategory = initial.first;
        } else {
          _selectedCategory = _firstCategory();
        }
        final message = _initialMessage;
        if (message != null) {
          _initialMessage = null;
          _initialPrefill = applyMessage(message);
        }
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// The category [t] was saved under. One that no longer exists is added
  /// back to the picker so editing never changes it silently.
  TransactionCategory _categoryOf(Transaction t) {
    final match = _categories
        .where((c) => c.type == t.type && c.name == t.categoryName)
        .firstOrNull;
    if (match != null) return match;
    final kept = TransactionCategory(
      id: 'kept-${t.categoryName}',
      name: t.categoryName,
      icon: t.categoryIcon,
      color: t.categoryColor,
      type: t.type,
    );
    _categories = [kept, ..._categories];
    return kept;
  }

  Future<Result<void>> _save(TransactionInput input) async {
    final amount = parseAmount(input.amount);
    final category = _selectedCategory;
    if (amount == null || amount <= 0 || category == null) {
      return Result.error(Exception('Incomplete transaction'));
    }
    final draft = TransactionDraft(
      title: input.title,
      amount: amount,
      category: category,
      date: _date,
      note: input.note,
      walletId: _selectedWalletId ?? Transaction.defaultWalletId,
    );
    final editing = _editing;
    if (editing != null) {
      final result = await _transactionRepository.updateTransaction(
        editing.id,
        draft,
      );
      return switch (result) {
        Ok() => const Result.ok(null),
        Error(:final error) => Result.error(error),
      };
    }
    final result = await _transactionRepository.addTransaction(draft);
    if (result case Error(:final error)) return Result.error(error);
    return _saveFee(input.title.trim().isEmpty ? category.name : input.title);
  }

  /// Saves the [pendingFee] (if any) as a Fees & charges expense from the
  /// same wallet.
  Future<Result<void>> _saveFee(String title) async {
    final fee = _pendingFee;
    final feeCategory = _categories
        .where((c) => c.id == feesCategoryId)
        .firstOrNull;
    if (fee == null || fee <= 0 || feeCategory == null) {
      return const Result.ok(null);
    }
    final result = await _transactionRepository.addTransaction(
      TransactionDraft(
        title: 'Charge: ${title.trim()}',
        amount: fee,
        category: feeCategory,
        date: _date,
        walletId: _selectedWalletId ?? Transaction.defaultWalletId,
      ),
    );
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  /// The category charges are recorded under.
  static const String feesCategoryId = 'c-fees';

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
