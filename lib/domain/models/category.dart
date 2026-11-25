import 'transaction.dart';

/// A spending or income category, e.g. Groceries or Salary.
///
/// [icon] is an icon key and [color] an ARGB value, so the model stays free
/// of Flutter types. The UI resolves both.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String name;
  final String icon;
  final int color;

  /// Whether this category is for expenses or income.
  final TransactionType type;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.type == type;

  @override
  int get hashCode => Object.hash(id, name, icon, color, type);

  @override
  String toString() => 'Category($id, $name)';
}
