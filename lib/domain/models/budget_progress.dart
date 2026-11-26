import 'budget.dart';
import 'budget_alert.dart';
import 'transaction.dart';

/// Where a budget stands this month.
enum BudgetStatus {
  /// Nothing spent yet.
  notStarted,

  /// Spending is below [BudgetProgress.alertThreshold].
  onTrack,

  /// At or above the alert threshold, but not over the limit.
  nearLimit,

  /// Spent more than the limit.
  overLimit,
}

/// How much of a [Budget] has been spent in one month.
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spent});

  /// Budgets at or above this fraction of their limit raise an alert.
  static const double alertThreshold = 0.8;

  final Budget budget;

  /// Expenses in the budget's category this month, positive.
  final double spent;

  /// Fraction of the limit spent: 0.97 means 97 %. Can exceed 1.
  double get percentUsed => budget.limit <= 0 ? 0 : spent / budget.limit;

  /// [percentUsed] as a whole percentage, e.g. 97.
  int get percentRounded => (percentUsed * 100).round();

  /// Amount left before the limit, never negative.
  double get remaining => spent >= budget.limit ? 0 : budget.limit - spent;

  /// Amount over the limit, never negative.
  double get overBy => spent > budget.limit ? spent - budget.limit : 0;

  bool get isOverLimit => spent > budget.limit;

  bool get needsAttention => percentUsed >= alertThreshold;

  BudgetStatus get status {
    if (isOverLimit) return BudgetStatus.overLimit;
    if (needsAttention) return BudgetStatus.nearLimit;
    if (spent <= 0) return BudgetStatus.notStarted;
    return BudgetStatus.onTrack;
  }

  BudgetAlert toAlert() => BudgetAlert(
    categoryName: budget.categoryName,
    percentUsed: percentUsed,
    remaining: remaining,
  );

  /// Progress for each budget from the expenses in [month].
  static List<BudgetProgress> forMonth(
    List<Budget> budgets,
    List<Transaction> transactions,
    DateTime month,
  ) => forPeriod(
    budgets,
    transactions,
    DateTime(month.year, month.month),
    DateTime(month.year, month.month + 1),
  );

  /// Progress for each budget from the expenses on or after [start] and
  /// before [end], e.g. one pay cycle.
  static List<BudgetProgress> forPeriod(
    List<Budget> budgets,
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    final spentByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.isIncome || !t.isBetween(start, end)) continue;
      spentByCategory.update(
        t.categoryName,
        (total) => total + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    return [
      for (final budget in budgets)
        BudgetProgress(
          budget: budget,
          spent: spentByCategory[budget.categoryName] ?? 0,
        ),
    ];
  }

  /// The budget furthest towards (or over) its limit, or null when none has
  /// reached [alertThreshold].
  static BudgetProgress? topAlert(List<BudgetProgress> progress) {
    BudgetProgress? top;
    for (final p in progress) {
      if (!p.needsAttention) continue;
      if (top == null || p.percentUsed > top.percentUsed) top = p;
    }
    return top;
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetProgress && other.budget == budget && other.spent == spent;

  @override
  int get hashCode => Object.hash(budget, spent);

  @override
  String toString() => 'BudgetProgress(${budget.categoryName}, $spent)';
}
