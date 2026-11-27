import 'package:drift/drift.dart';

import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../utils/ids.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/database/table_watcher.dart';
import 'transaction_repository.dart';

/// [TransactionRepository] stored in the on-device database and synced to
/// Supabase. Deleting marks the row so the deletion syncs too.
class TransactionRepositoryDrift extends TransactionRepository
    with TableWatcher {
  TransactionRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    watchTables(_db, [_db.transactions]);
  }

  final AppDatabase _db;
  final DateTime Function() _clock;

  SimpleSelectStatement<$TransactionsTable, TransactionRow> get _live =>
      _db.select(_db.transactions)..where((t) => t.deleted.equals(false));

  @override
  Future<Result<List<Transaction>>> getTransactions() => guard(() async {
    final rows = await (_live..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return [for (final r in rows) r.toDomain()];
  });

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 5}) =>
      guard(() async {
        final rows =
            await (_live
                  ..orderBy([(t) => OrderingTerm.desc(t.date)])
                  ..limit(limit))
                .get();
        return [for (final r in rows) r.toDomain()];
      });

  @override
  Future<Result<MonthlySummary>> getMonthlySummary({DateTime? month}) =>
      guard(() async {
        final target = month ?? _clock();
        final start = DateTime(target.year, target.month);
        final end = DateTime(target.year, target.month + 1);
        final rows =
            await (_live..where(
                  (t) =>
                      t.date.isBiggerOrEqualValue(start) &
                      t.date.isSmallerThanValue(end),
                ))
                .get();
        var income = 0.0;
        var expenses = 0.0;
        for (final r in rows) {
          if (r.type == TransactionType.income.name) {
            income += r.amount;
          } else {
            expenses += r.amount;
          }
        }
        return MonthlySummary(
          month: start,
          income: income,
          expenses: expenses,
          net: income - expenses,
        );
      });

  @override
  Future<Result<Transaction>> addTransaction(TransactionDraft draft) =>
      guard(() async {
        final transaction = draft.toTransaction(newId());
        await _db
            .into(_db.transactions)
            .insert(transaction.toCompanion(modifiedAt: _clock()));
        return transaction;
      });

  @override
  Future<Result<Transaction>> updateTransaction(
    String id,
    TransactionDraft draft,
  ) => guard(() async {
    final transaction = draft.toTransaction(id);
    final count =
        await (_db.update(_db.transactions)
              ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
            .write(transaction.toCompanion(modifiedAt: _clock()));
    if (count == 0) throw Exception('Transaction $id not found');
    return transaction;
  });

  @override
  Future<Result<void>> deleteTransaction(String id) => guard(() async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });
}
