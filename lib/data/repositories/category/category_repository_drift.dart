import 'package:drift/drift.dart';

import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import 'category_repository.dart';
import 'default_categories.dart';

/// [CategoryRepository] stored in the on-device database and synced to
/// Supabase.
class CategoryRepositoryDrift implements CategoryRepository {
  CategoryRepositoryDrift(this._db);

  final AppDatabase _db;

  /// Seeds are older than any real edit, so the server's copy (seeded
  /// with the same ids when the account was created) always wins.
  static final DateTime seedTime = DateTime.utc(2000);

  @override
  Future<Result<List<TransactionCategory>>> getCategories({
    TransactionType? type,
  }) => guard(() async {
    await _seedIfEmpty();
    final query = _db.select(_db.categories)
      ..where((c) => c.deleted.equals(false))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    if (type != null) query.where((c) => c.type.equals(type.name));
    final rows = await query.get();
    return [for (final r in rows) r.toDomain()];
  });

  /// A new device has the default categories before its first sync.
  Future<void> _seedIfEmpty() async {
    final count = await _db.categories.count().getSingle();
    if (count > 0) return;
    await _db.batch((batch) {
      for (final (i, c) in DefaultCategories.all.indexed) {
        batch.insert(
          _db.categories,
          c.toCompanion(modifiedAt: seedTime, sortOrder: i, dirty: false),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
