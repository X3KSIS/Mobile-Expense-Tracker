import '../../../domain/models/category.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';
import 'category_repository.dart';
import 'fake_categories.dart';

/// In-memory [CategoryRepository] backed by [FakeCategories].
class CategoryRepositoryLocalFake implements CategoryRepository {
  CategoryRepositoryLocalFake({this.delay = const Duration(milliseconds: 200)});

  /// Simulated network latency.
  final Duration delay;

  @override
  Future<Result<List<Category>>> getCategories({TransactionType? type}) async {
    await Future<void>.delayed(delay);
    return Result.ok(
      List.unmodifiable(
        FakeCategories.all.where((c) => type == null || c.type == type),
      ),
    );
  }
}
