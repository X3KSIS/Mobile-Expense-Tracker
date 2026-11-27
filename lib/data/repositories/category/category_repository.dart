import 'package:flutter/foundation.dart';

import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';

/// Why a category change was refused.
enum CategoryProblem {
  /// The name is blank.
  emptyName,

  /// Another category of the same type already has this name.
  duplicateName,

  /// The category is needed by the app (Fees & charges holds charges).
  protected,

  /// It is the only category of its type left.
  lastOfType,
}

/// Returned inside `Result.error` when a category change is refused.
class CategoryException implements Exception {
  const CategoryException(this.problem);

  final CategoryProblem problem;

  @override
  String toString() => 'CategoryException(${problem.name})';
}

/// Source of truth for categories: the defaults plus the user's own, in
/// the user's order. Notifies after every change.
abstract class CategoryRepository extends ChangeNotifier {
  /// Categories that cannot be deleted: Fees & charges holds the charges
  /// read from mobile money messages.
  static const Set<String> protectedIds = {'c-fees'};

  /// All categories, or only those of [type] when given, in order.
  Future<Result<List<TransactionCategory>>> getCategories({
    TransactionType? type,
  });

  /// Adds [category] when its id is empty, otherwise updates it. Renaming
  /// or changing the icon also updates the transactions and budgets filed
  /// under it, so reports stay continuous.
  Future<Result<TransactionCategory>> saveCategory(
    TransactionCategory category,
  );

  /// Removes the category from the pickers. Past transactions keep its
  /// name.
  Future<Result<void>> deleteCategory(String id);

  /// Saves the order of [type]'s categories.
  Future<Result<void>> reorderCategories(
    TransactionType type,
    List<String> orderedIds,
  );
}
