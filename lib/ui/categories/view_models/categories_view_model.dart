import 'package:flutter/foundation.dart';

import '../../../data/repositories/category/category_repository.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for Manage categories: the expense or income list in the user's
/// order, and adding, editing, deleting and reordering. Reloads when
/// categories change.
class CategoriesViewModel extends ChangeNotifier {
  CategoriesViewModel({required this._categoryRepository}) {
    _categoryRepository.addListener(_onChanged);
    load = Command0<void>(_load)..execute();
    save = Command1<TransactionCategory, TransactionCategory>(_save);
    delete = Command1<void, String>(_categoryRepository.deleteCategory);
    reorder = Command1<void, (int, int)>(_reorder);
  }

  final CategoryRepository _categoryRepository;

  late final Command0<void> load;
  late final Command1<TransactionCategory, TransactionCategory> save;
  late final Command1<void, String> delete;
  late final Command1<void, (int, int)> reorder;

  List<TransactionCategory> _all = const [];
  TransactionType _type = TransactionType.expense;
  bool _loaded = false;
  bool _disposed = false;

  TransactionType get type => _type;

  /// The selected type's categories, in order.
  List<TransactionCategory> get categories =>
      _all.where((c) => c.type == _type).toList(growable: false);

  bool get isLoading => load.running && !_loaded;

  bool get hasError => load.error && !_loaded;

  /// Whether [category] may be deleted (Fees & charges may not).
  bool canDelete(TransactionCategory category) =>
      !CategoryRepository.protectedIds.contains(category.id) &&
      categories.length > 1;

  void selectType(TransactionType type) {
    if (type == _type) return;
    _type = type;
    _notify();
  }

  /// A blank category of the selected type, for the add sheet.
  TransactionCategory blank() => TransactionCategory(
    id: '',
    name: '',
    icon: 'other',
    color: 0,
    type: _type,
  );

  /// Words for a refused change.
  static String messageFor(Exception error) => switch (error) {
    CategoryException(problem: CategoryProblem.emptyName) =>
      'Give the category a name.',
    CategoryException(problem: CategoryProblem.duplicateName) =>
      'You already have a category with that name.',
    CategoryException(problem: CategoryProblem.protected) =>
      "Fees & charges can't be deleted: charges from mobile money "
          'messages are saved there.',
    CategoryException(problem: CategoryProblem.lastOfType) =>
      'Keep at least one category of each type.',
    _ => "Couldn't save. Please try again.",
  };

  Future<Result<TransactionCategory>> _save(TransactionCategory category) =>
      _categoryRepository.saveCategory(category);

  /// Moves the category at [from] to [to] (ReorderableList indices) and
  /// saves the order. The list updates at once.
  Future<Result<void>> _reorder((int, int) move) async {
    final (from, to) = move;
    final list = [...categories];
    final item = list.removeAt(from);
    list.insert(to > from ? to - 1 : to, item);
    final others = _all.where((c) => c.type != _type);
    _all = [...list, ...others];
    _notify();
    return _categoryRepository.reorderCategories(_type, [
      for (final c in list) c.id,
    ]);
  }

  void _onChanged() {
    if (!_disposed) load.execute();
  }

  Future<Result<void>> _load() async {
    final result = await _categoryRepository.getCategories();
    switch (result) {
      case Ok(:final value):
        _all = value;
        _loaded = true;
        _notify();
        return const Result.ok(null);
      case Error(:final error):
        _notify();
        return Result.error(error);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _categoryRepository.removeListener(_onChanged);
    load.dispose();
    save.dispose();
    delete.dispose();
    reorder.dispose();
    super.dispose();
  }
}
