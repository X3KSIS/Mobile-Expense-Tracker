import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';
import 'category_repository.dart';
import 'default_categories.dart';

/// In-memory [CategoryRepository] starting from [DefaultCategories], for
/// tests.
class CategoryRepositoryLocalFake extends CategoryRepository {
  CategoryRepositoryLocalFake({this.delay = const Duration(milliseconds: 200)});

  /// Simulated network latency.
  final Duration delay;

  final List<TransactionCategory> _categories = [...DefaultCategories.all];
  int _nextId = 1;

  @override
  Future<Result<List<TransactionCategory>>> getCategories({
    TransactionType? type,
  }) async {
    await Future<void>.delayed(delay);
    return Result.ok(
      List.unmodifiable(
        _categories.where((c) => type == null || c.type == type),
      ),
    );
  }

  @override
  Future<Result<TransactionCategory>> saveCategory(
    TransactionCategory category,
  ) async {
    await Future<void>.delayed(delay);
    final name = category.name.trim();
    if (name.isEmpty) {
      return const Result.error(CategoryException(CategoryProblem.emptyName));
    }
    final clash = _categories.any(
      (c) =>
          c.id != category.id &&
          c.type == category.type &&
          c.name.toLowerCase() == name.toLowerCase(),
    );
    if (clash) {
      return const Result.error(
        CategoryException(CategoryProblem.duplicateName),
      );
    }
    final saved = TransactionCategory(
      id: category.id.isEmpty ? 'c-new-${_nextId++}' : category.id,
      name: name,
      icon: category.icon,
      color: category.color,
      type: category.type,
    );
    final index = _categories.indexWhere((c) => c.id == saved.id);
    if (index < 0) {
      _categories.add(saved);
    } else {
      _categories[index] = saved;
    }
    notifyListeners();
    return Result.ok(saved);
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    await Future<void>.delayed(delay);
    if (CategoryRepository.protectedIds.contains(id)) {
      return const Result.error(CategoryException(CategoryProblem.protected));
    }
    final category = _categories.where((c) => c.id == id).firstOrNull;
    if (category == null) return const Result.ok(null);
    if (_categories.where((c) => c.type == category.type).length <= 1) {
      return const Result.error(CategoryException(CategoryProblem.lastOfType));
    }
    _categories.remove(category);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> reorderCategories(
    TransactionType type,
    List<String> orderedIds,
  ) async {
    await Future<void>.delayed(delay);
    int rank(TransactionCategory c) {
      final i = orderedIds.indexOf(c.id);
      return i < 0 ? orderedIds.length : i;
    }

    final ofType = _categories.where((c) => c.type == type).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    final others = _categories.where((c) => c.type != type).toList();
    _categories
      ..clear()
      ..addAll(type == TransactionType.expense ? ofType : others)
      ..addAll(type == TransactionType.expense ? others : ofType);
    notifyListeners();
    return const Result.ok(null);
  }
}
