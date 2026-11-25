/// A monthly spending limit for one expense category.
class Budget {
  const Budget({
    required this.id,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.limit,
  });

  final String id;

  /// Matches `Transaction.categoryName`.
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;

  /// Monthly limit, positive.
  final double limit;

  Budget copyWith({double? limit}) => Budget(
    id: id,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    limit: limit ?? this.limit,
  );

  @override
  bool operator ==(Object other) =>
      other is Budget &&
      other.id == id &&
      other.categoryName == categoryName &&
      other.categoryIcon == categoryIcon &&
      other.categoryColor == categoryColor &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(id, categoryName, categoryIcon, categoryColor, limit);

  @override
  String toString() => 'Budget($categoryName, limit: $limit)';
}
