/// Income, expenses and net balance for one month.
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
  });

  /// Any date within the month this summary covers.
  final DateTime month;

  /// Total income, positive.
  final double income;

  /// Total expenses, positive.
  final double expenses;

  /// income - expenses.
  final double net;

  @override
  bool operator ==(Object other) =>
      other is MonthlySummary &&
      other.month == month &&
      other.income == income &&
      other.expenses == expenses &&
      other.net == net;

  @override
  int get hashCode => Object.hash(month, income, expenses, net);

  @override
  String toString() =>
      'MonthlySummary(income: $income, expenses: $expenses, net: $net)';
}
