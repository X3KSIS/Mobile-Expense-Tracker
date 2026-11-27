import 'package:flutter/foundation.dart';

import '../../../data/repositories/budget/budget_repository.dart';
import '../../../data/repositories/category/category_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/transaction/transaction_repository.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/budget_progress.dart';
import '../../../domain/models/pay_cycle.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/command.dart';
import '../../../utils/currency.dart';
import '../../../utils/result.dart';

/// What the budget sheet submits. [budget] is null when adding, in which
/// case [category] is required.
typedef BudgetInput = ({
  Budget? budget,
  TransactionCategory? category,
  String limit,
});

/// State for the Budgets tab: this pay cycle's progress for each budget
/// (a calendar month when payday is the 1st), plus adding, editing,
/// deleting and reordering budgets. Reloads when budgets, transactions or
/// the payday change.
class BudgetsViewModel extends ChangeNotifier {
  BudgetsViewModel({
    required this._budgetRepository,
    required this._transactionRepository,
    required this._categoryRepository,
    required this._settingsRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _budgetRepository.addListener(_onDataChanged);
    _transactionRepository.addListener(_onDataChanged);
    _settingsRepository.addListener(_onDataChanged);
    load = Command0<void>(_load)..execute();
    save = Command1<void, BudgetInput>(_save);
    delete = Command1<void, String>(_budgetRepository.deleteBudget);
    reorder = Command1<void, (int, int)>(_reorder);
  }

  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final DateTime Function() _clock;

  late final Command0<void> load;
  late final Command1<void, BudgetInput> save;
  late final Command1<void, String> delete;

  /// Moves the budget at the first index so it ends up at the second.
  /// The new order shows straight away and is then saved.
  late final Command1<void, (int, int)> reorder;

  List<BudgetProgress> _progress = const [];
  List<TransactionCategory> _expenseCategories = const [];
  bool _loaded = false;
  bool _disposed = false;

  /// Budgets with this month's spending, in the user's order.
  List<BudgetProgress> get progress => _progress;

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  bool get isEmpty => _loaded && _progress.isEmpty;

  /// The pay cycle budgets are measured over.
  PayCycle get cycle =>
      PayCycle.containing(_clock(), _settingsRepository.payday);

  /// Any date in the current cycle.
  DateTime get month => _clock();

  /// Days left until the next payday (or month end), including today.
  int get daysLeft => cycle.daysLeft(_clock());

  /// How much can still be spent each day for the rest of the month
  /// without going over [progress]'s limit.
  double dailyAllowance(BudgetProgress progress) =>
      progress.remaining / daysLeft;

  /// Average spent per day so far this cycle.
  double dailyAverage(BudgetProgress progress) =>
      progress.spent / cycle.daysElapsed(_clock());

  double get totalLimit => _progress.fold(0, (sum, p) => sum + p.budget.limit);

  double get totalSpent => _progress.fold(0, (sum, p) => sum + p.spent);

  double get totalRemaining =>
      totalSpent >= totalLimit ? 0 : totalLimit - totalSpent;

  double get totalPercentUsed => totalLimit <= 0 ? 0 : totalSpent / totalLimit;

  /// How many budgets are over their limit.
  int get overCount => _progress.where((p) => p.isOverLimit).length;

  /// Expense categories that do not have a budget yet.
  List<TransactionCategory> get availableCategories {
    final taken = {for (final p in _progress) p.budget.categoryName};
    return _expenseCategories
        .where((c) => !taken.contains(c.name))
        .toList(growable: false);
  }

  /// Form validator for the limit field.
  String? validateLimit(String? value) {
    final amount = parseAmount(value ?? '');
    if (amount == null) return 'Enter a monthly limit';
    if (amount <= 0) return 'The limit must be more than zero';
    return null;
  }

  void _onDataChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final results = await (
      _budgetRepository.getBudgets(),
      _transactionRepository.getTransactions(),
      _categoryRepository.getCategories(type: TransactionType.expense),
    ).wait;
    switch (results) {
      case (
        Ok(value: final budgets),
        Ok(value: final transactions),
        Ok(value: final categories),
      ):
        final c = cycle;
        _progress = BudgetProgress.forPeriod(
          budgets,
          transactions,
          c.start,
          c.end,
          alertAt: _settingsRepository.budgetAlertPercent / 100,
        );
        _expenseCategories = categories;
        _loaded = true;
        _notify();
        return const Result.ok(null);
      case (Error(:final error), _, _) ||
          (_, Error(:final error), _) ||
          (_, _, Error(:final error)):
        _notify();
        return Result.error(error);
    }
  }

  Future<Result<void>> _save(BudgetInput input) async {
    final limit = parseAmount(input.limit);
    if (limit == null || limit <= 0) {
      return Result.error(Exception('Invalid limit'));
    }
    final existing = input.budget;
    final category = input.category;
    final Budget budget;
    if (existing != null) {
      budget = existing.copyWith(limit: limit);
    } else if (category != null) {
      budget = Budget(
        id: '',
        categoryName: category.name,
        categoryIcon: category.icon,
        categoryColor: category.color,
        limit: limit,
      );
    } else {
      return Result.error(Exception('Pick a category'));
    }
    final result = await _budgetRepository.saveBudget(budget);
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<void>> _reorder((int, int) move) async {
    final (from, target) = move;
    if (from < 0 || from >= _progress.length) {
      return Result.error(Exception('No budget at index $from'));
    }
    final to = target.clamp(0, _progress.length - 1);
    if (to == from) return const Result.ok(null);
    final reordered = [..._progress];
    reordered.insert(to, reordered.removeAt(from));
    _progress = reordered;
    _notify();
    return _budgetRepository.reorderBudgets([
      for (final p in reordered) p.budget.id,
    ]);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _budgetRepository.removeListener(_onDataChanged);
    _transactionRepository.removeListener(_onDataChanged);
    _settingsRepository.removeListener(_onDataChanged);
    load.dispose();
    save.dispose();
    delete.dispose();
    reorder.dispose();
    super.dispose();
  }
}
