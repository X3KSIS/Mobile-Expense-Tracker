import '../../../domain/models/category.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';

/// Source of truth for categories.
abstract class CategoryRepository {
  /// All categories, or only those of [type] when given.
  Future<Result<List<Category>>> getCategories({TransactionType? type});
}
