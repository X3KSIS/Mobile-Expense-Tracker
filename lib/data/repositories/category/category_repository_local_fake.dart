import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';
import 'category_repository.dart';
import 'default_categories.dart';

/// In-memory [CategoryRepository] backed by [DefaultCategories].
class CategoryRepositoryLocalFake implements CategoryRepository {
  CategoryRepositoryLocalFake({this.delay = const Duration(milliseconds: 200)});

  /// Simulated network latency.
  final Duration delay;

  @override
  Future<Result<List<TransactionCategory>>> getCategories({
    TransactionType? type,
  }) async {
    await Future<void>.delayed(delay);
    return Result.ok(
      List.unmodifiable(
        DefaultCategories.all.where((c) => type == null || c.type == type),
      ),
    );
  }
}
