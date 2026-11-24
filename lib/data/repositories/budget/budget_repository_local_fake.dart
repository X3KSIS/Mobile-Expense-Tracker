import '../../../domain/models/budget_alert.dart';
import '../../../utils/result.dart';
import 'budget_repository.dart';

/// In-memory [BudgetRepository] with realistic ZMW mock budgets.
///
/// Groceries: ZMW 3,200 of 3,300 spent, so 97 % used and ZMW 100 left.
class BudgetRepositoryLocalFake implements BudgetRepository {
  BudgetRepositoryLocalFake({this.delay = const Duration(milliseconds: 400)});

  /// Simulated network latency.
  final Duration delay;

  /// Budgets at or above this fraction of their limit raise an alert.
  static const double alertThreshold = 0.8;

  static const List<_FakeBudget> _budgets = [
    _FakeBudget('Groceries', limit: 3300, spent: 3200),
    _FakeBudget('Transport', limit: 1500, spent: 530),
    _FakeBudget('Utilities', limit: 800, spent: 300),
    _FakeBudget('Airtime', limit: 300, spent: 150),
  ];

  @override
  Future<Result<BudgetAlert?>> getTopAlert() async {
    await Future<void>.delayed(delay);
    _FakeBudget? top;
    for (final budget in _budgets) {
      if (budget.percentUsed < alertThreshold) continue;
      if (top == null || budget.percentUsed > top.percentUsed) top = budget;
    }
    if (top == null) return const Result.ok(null);
    return Result.ok(
      BudgetAlert(
        categoryName: top.categoryName,
        percentUsed: top.percentUsed,
        remaining: top.remaining,
      ),
    );
  }
}

class _FakeBudget {
  const _FakeBudget(
    this.categoryName, {
    required this.limit,
    required this.spent,
  });

  final String categoryName;
  final double limit;
  final double spent;

  double get percentUsed => spent / limit;

  double get remaining => spent >= limit ? 0 : limit - spent;
}
