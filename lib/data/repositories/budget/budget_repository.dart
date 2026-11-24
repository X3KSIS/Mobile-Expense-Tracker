import '../../../domain/models/budget_alert.dart';
import '../../../utils/result.dart';

/// Source of truth for budgets.
abstract class BudgetRepository {
  /// The budget closest to (or furthest over) its limit, or null when no
  /// budget has reached the alert threshold.
  Future<Result<BudgetAlert?>> getTopAlert();
}
