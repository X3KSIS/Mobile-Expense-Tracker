import 'package:drift/drift.dart';

import '../../../domain/models/budget.dart';
import '../../../utils/ids.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/database/table_watcher.dart';
import 'budget_repository.dart';

/// [BudgetRepository] stored in the on-device database and synced to
/// Supabase. The user's order is kept in `sortOrder`.
class BudgetRepositoryDrift extends BudgetRepository with TableWatcher {
  BudgetRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    watchTables(_db, [_db.budgets]);
  }

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<List<BudgetRow>> _rows() =>
      (_db.select(_db.budgets)
            ..where((b) => b.deleted.equals(false))
            ..orderBy([
              (b) => OrderingTerm.asc(b.sortOrder),
              (b) => OrderingTerm.asc(b.modifiedAt),
            ]))
          .get();

  @override
  Future<Result<List<Budget>>> getBudgets() => guard(() async {
    return [for (final r in await _rows()) r.toDomain()];
  });

  @override
  Future<Result<Budget>> saveBudget(Budget budget) => guard(() async {
    final saved = budget.id.isEmpty
        ? Budget(
            id: newId(),
            categoryName: budget.categoryName,
            categoryIcon: budget.categoryIcon,
            categoryColor: budget.categoryColor,
            limit: budget.limit,
          )
        : budget;
    final existing = await (_db.select(
      _db.budgets,
    )..where((b) => b.id.equals(saved.id))).getSingleOrNull();
    final sortOrder = existing?.sortOrder ?? (await _rows()).length;
    await _db
        .into(_db.budgets)
        .insertOnConflictUpdate(
          saved.toCompanion(modifiedAt: _clock(), sortOrder: sortOrder),
        );
    return saved;
  });

  @override
  Future<Result<void>> deleteBudget(String id) => guard(() async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });

  @override
  Future<Result<void>> reorderBudgets(List<String> orderedIds) =>
      guard(() async {
        final rows = await _rows();
        int rank(BudgetRow b) {
          final i = orderedIds.indexOf(b.id);
          return i == -1 ? orderedIds.length : i;
        }

        final sorted = [...rows]..sort((a, b) => rank(a).compareTo(rank(b)));
        final now = _clock();
        await _db.batch((batch) {
          for (final (i, row) in sorted.indexed) {
            if (row.sortOrder == i) continue;
            batch.update(
              _db.budgets,
              BudgetsCompanion(
                sortOrder: Value(i),
                dirty: const Value(true),
                modifiedAt: Value(now),
              ),
              where: (b) => b.id.equals(row.id),
            );
          }
        });
      });
}
