import 'budget.dart';
import 'budget_progress.dart';
import 'pay_cycle.dart';
import 'transaction.dart';

/// What was spent on one category this pay cycle, and its budget if it
/// has one.
class CategorySpend {
  const CategorySpend({
    required this.name,
    required this.icon,
    required this.amount,
    this.budget,
  });

  final String name;
  final String icon;
  final double amount;

  /// The category's budget progress this cycle, or null without a budget.
  final BudgetProgress? budget;

  @override
  bool operator ==(Object other) =>
      other is CategorySpend &&
      other.name == name &&
      other.amount == amount &&
      other.budget == budget;

  @override
  int get hashCode => Object.hash(name, amount, budget);
}

/// Spending in the current pay cycle: the total, how it compares with the
/// same point in the last cycle, each day's spending, and where it went.
class CycleSpending {
  const CycleSpending({
    required this.cycle,
    required this.spent,
    required this.lastCycleSoFar,
    required this.daily,
    required this.today,
    required this.categories,
  });

  final PayCycle cycle;

  /// Spent from the start of the cycle to now.
  final double spent;

  /// Spent in the last cycle by the same day, or null when nothing was
  /// spent in the whole last cycle (nothing to compare with).
  final double? lastCycleSoFar;

  /// What was spent on each day of the cycle, from its first day; days
  /// still to come are 0.
  final List<double> daily;

  /// Index of today in [daily].
  final int today;

  /// Categories spent on this cycle, most first.
  final List<CategorySpend> categories;

  /// [spent] minus [lastCycleSoFar]: positive means spending more.
  double? get change {
    final last = lastCycleSoFar;
    return last == null ? null : spent - last;
  }

  static CycleSpending compute({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required PayCycle cycle,
    required DateTime now,
    double alertAt = BudgetProgress.defaultAlertAt,
  }) {
    final expenses = [
      for (final t in transactions)
        if (t.type == TransactionType.expense) t,
    ];
    final thisCycle = [
      for (final t in expenses)
        if (cycle.contains(t.date) && !t.date.isAfter(now)) t,
    ];

    final daily = List<double>.filled(cycle.lengthInDays, 0);
    for (final t in thisCycle) {
      final index = cycle.daysElapsed(t.date) - 1;
      daily[index] += t.amount;
    }

    final last = PayCycle.containing(
      cycle.start.subtract(const Duration(days: 1)),
      cycle.start.day,
    );
    final elapsed = now.difference(cycle.start);
    final samePoint = last.start.add(elapsed);
    var lastTotal = 0.0;
    var lastSoFar = 0.0;
    for (final t in expenses) {
      if (!last.contains(t.date)) continue;
      lastTotal += t.amount;
      if (!t.date.isAfter(samePoint)) lastSoFar += t.amount;
    }

    final byName = <String, ({String icon, double amount})>{};
    for (final t in thisCycle) {
      final current = byName[t.categoryName];
      byName[t.categoryName] = (
        icon: current?.icon ?? t.categoryIcon,
        amount: (current?.amount ?? 0) + t.amount,
      );
    }
    final progress = {
      for (final p in BudgetProgress.forPeriod(
        budgets,
        thisCycle,
        cycle.start,
        cycle.end,
        alertAt: alertAt,
      ))
        p.budget.categoryName: p,
    };
    final categories = [
      for (final MapEntry(:key, :value) in byName.entries)
        CategorySpend(
          name: key,
          icon: value.icon,
          amount: value.amount,
          budget: progress[key],
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return CycleSpending(
      cycle: cycle,
      spent: thisCycle.fold(0, (sum, t) => sum + t.amount),
      lastCycleSoFar: lastTotal > 0 ? lastSoFar : null,
      daily: daily,
      today: cycle.daysElapsed(now) - 1,
      categories: categories,
    );
  }
}
