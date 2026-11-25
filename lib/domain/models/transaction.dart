/// Whether money came in or went out.
enum TransactionType { income, expense }

/// A single income or expense entry.
///
/// [categoryIcon] is an icon key (e.g. `groceries`) and [categoryColor] an
/// ARGB value, so the model stays free of Flutter types and maps directly to
/// what the Django API stores. The UI resolves both.
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
  });

  final String id;
  final String title;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;

  /// Always positive. The sign comes from [type].
  final double amount;
  final TransactionType type;
  final DateTime date;

  /// Optional free-text note.
  final String? note;

  bool get isIncome => type == TransactionType.income;

  /// Amount with sign applied: positive for income, negative for expenses.
  double get signedAmount => isIncome ? amount : -amount;

  /// Whether [date] falls in the same calendar month as [month].
  bool isInMonth(DateTime month) =>
      date.year == month.year && date.month == month.month;

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.title == title &&
      other.categoryName == categoryName &&
      other.categoryIcon == categoryIcon &&
      other.categoryColor == categoryColor &&
      other.amount == amount &&
      other.type == type &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    categoryName,
    categoryIcon,
    categoryColor,
    amount,
    type,
    date,
    note,
  );

  @override
  String toString() =>
      'Transaction($id, $title, ${type.name} $amount, $categoryName, $date)';
}
