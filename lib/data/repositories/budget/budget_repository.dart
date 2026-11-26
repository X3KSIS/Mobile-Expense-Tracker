import 'package:flutter/foundation.dart';

import '../../../domain/models/budget.dart';
import '../../../utils/result.dart';

/// Source of truth for monthly budgets.
///
/// Extends [ChangeNotifier] and notifies after every save or delete.
/// Progress is worked out from transactions with `BudgetProgress.forMonth`.
abstract class BudgetRepository extends ChangeNotifier {
  Future<Result<List<Budget>>> getBudgets();

  /// Adds [budget], or replaces the budget with the same id.
  Future<Result<Budget>> saveBudget(Budget budget);

  Future<Result<void>> deleteBudget(String id);

  /// Saves the user's order of budgets. [orderedIds] lists budget ids in
  /// the new order; budgets missing from it keep their place at the end.
  Future<Result<void>> reorderBudgets(List<String> orderedIds);
}
