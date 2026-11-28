import 'package:drift/drift.dart';

import '../../../domain/models/bill.dart';
import '../../../utils/ids.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/database/table_watcher.dart';
import 'bill_repository.dart';

/// [BillRepository] stored in the on-device database and synced to
/// Supabase. Deleting marks the row so the deletion syncs too.
class BillRepositoryDrift extends BillRepository with TableWatcher {
  BillRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    watchTables(_db, [_db.bills]);
  }

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<Result<List<Bill>>> getBills() => guard(() async {
    final rows =
        await (_db.select(_db.bills)
              ..where((b) => b.deleted.equals(false))
              ..orderBy([(b) => OrderingTerm.asc(b.nextDue)]))
            .get();
    return [for (final r in rows) r.toDomain()];
  });

  @override
  Future<Result<Bill>> saveBill(Bill bill) => guard(() async {
    final saved = bill.id.isEmpty ? bill.copyWith(id: newId()) : bill;
    await _db
        .into(_db.bills)
        .insertOnConflictUpdate(saved.toCompanion(modifiedAt: _clock()));
    return saved;
  });

  @override
  Future<Result<void>> deleteBill(String id) => guard(() async {
    await (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });
}
