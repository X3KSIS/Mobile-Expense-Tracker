import '../../../domain/models/budget.dart';
import '../../../domain/models/category.dart';
import '../../../utils/result.dart';
import '../category/fake_categories.dart';
import 'budget_repository.dart';

/// In-memory [BudgetRepository] with realistic ZMW mock budgets.
///
/// With the fake transactions, Groceries is ZMW 3,200 of 3,300 (97 %, ZMW
/// 100 left) this month.
class BudgetRepositoryLocalFake extends BudgetRepository {
  BudgetRepositoryLocalFake({this.delay = const Duration(milliseconds: 400)});

  /// Simulated network latency.
  final Duration delay;

  final List<Budget> _budgets = [
    _budget(FakeCategories.groceries, 3300),
    _budget(FakeCategories.transport, 1500),
    _budget(FakeCategories.utilities, 800),
    _budget(FakeCategories.airtime, 300),
    _budget(FakeCategories.eatingOut, 600),
  ];
  int _nextId = 1;

  static Budget _budget(Category category, double limit) => Budget(
    id: 'b-${category.id}',
    categoryName: category.name,
    categoryIcon: category.icon,
    categoryColor: category.color,
    limit: limit,
  );

  @override
  Future<Result<List<Budget>>> getBudgets() async {
    await Future<void>.delayed(delay);
    return Result.ok(List.unmodifiable(_budgets));
  }

  @override
  Future<Result<Budget>> saveBudget(Budget budget) async {
    await Future<void>.delayed(delay);
    final saved = budget.id.isEmpty
        ? Budget(
            id: 'b-new-${_nextId++}',
            categoryName: budget.categoryName,
            categoryIcon: budget.categoryIcon,
            categoryColor: budget.categoryColor,
            limit: budget.limit,
          )
        : budget;
    final index = _budgets.indexWhere((b) => b.id == saved.id);
    if (index == -1) {
      _budgets.add(saved);
    } else {
      _budgets[index] = saved;
    }
    notifyListeners();
    return Result.ok(saved);
  }

  @override
  Future<Result<void>> deleteBudget(String id) async {
    await Future<void>.delayed(delay);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    return const Result.ok(null);
  }
}
