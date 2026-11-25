import 'category.dart';
import 'transaction.dart';

/// What the user entered for a new transaction, before it has an id.
class TransactionDraft {
  const TransactionDraft({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  /// Falls back to the category name when blank.
  final String title;

  /// Always positive.
  final double amount;
  final Category category;
  final DateTime date;
  final String? note;

  TransactionType get type => category.type;

  /// Builds the stored [Transaction] with the given [id].
  Transaction toTransaction(String id) {
    final trimmedTitle = title.trim();
    final trimmedNote = note?.trim();
    return Transaction(
      id: id,
      title: trimmedTitle.isEmpty ? category.name : trimmedTitle,
      categoryName: category.name,
      categoryIcon: category.icon,
      categoryColor: category.color,
      amount: amount,
      type: category.type,
      date: date,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
  }
}
