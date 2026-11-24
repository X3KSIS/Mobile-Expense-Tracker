/// A budget that is close to, or over, its limit.
class BudgetAlert {
  const BudgetAlert({
    required this.categoryName,
    required this.percentUsed,
    required this.remaining,
  });

  final String categoryName;

  /// Fraction of the limit spent: 0.97 means 97 %. Can exceed 1.
  final double percentUsed;

  /// Amount left before the limit, never negative.
  final double remaining;

  /// [percentUsed] as a whole percentage, e.g. 97.
  int get percentRounded => (percentUsed * 100).round();

  bool get isOverLimit => percentUsed >= 1;

  @override
  bool operator ==(Object other) =>
      other is BudgetAlert &&
      other.categoryName == categoryName &&
      other.percentUsed == percentUsed &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(categoryName, percentUsed, remaining);

  @override
  String toString() =>
      'BudgetAlert($categoryName, $percentRounded%, remaining: $remaining)';
}
