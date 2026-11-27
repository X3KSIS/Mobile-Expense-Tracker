import 'package:drift/drift.dart';

import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../utils/ids.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/database/table_watcher.dart';
import 'category_repository.dart';
import 'default_categories.dart';

/// [CategoryRepository] stored in the on-device database and synced to
/// Supabase.
class CategoryRepositoryDrift extends CategoryRepository with TableWatcher {
  CategoryRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    watchTables(_db, [_db.categories]);
  }

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Seeds are older than any real edit, so the server's copy (seeded
  /// with the same ids when the account was created) always wins.
  static final DateTime seedTime = DateTime.utc(2000);

  /// Stored colours for new categories, in turn. Colour is data for the
  /// server; icons, not colours, tell categories apart in the app.
  static const List<int> _palette = [
    0xFF2F6FDB,
    0xFFD9467A,
    0xFF1F8A8A,
    0xFF7A4CD9,
    0xFFB7791F,
    0xFF2E8B57,
  ];

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _live({
    TransactionType? type,
  }) {
    final query = _db.select(_db.categories)
      ..where((c) => c.deleted.equals(false))
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.modifiedAt),
      ]);
    if (type != null) query.where((c) => c.type.equals(type.name));
    return query;
  }

  @override
  Future<Result<List<TransactionCategory>>> getCategories({
    TransactionType? type,
  }) => guard(() async {
    await _seedIfEmpty();
    final rows = await _live(type: type).get();
    return [for (final r in rows) r.toDomain()];
  });

  @override
  Future<Result<TransactionCategory>> saveCategory(
    TransactionCategory category,
  ) => guard(() async {
    final name = category.name.trim();
    if (name.isEmpty) {
      throw const CategoryException(CategoryProblem.emptyName);
    }
    final sameType = await _live(type: category.type).get();
    final clash = sameType.any(
      (c) => c.id != category.id && c.name.toLowerCase() == name.toLowerCase(),
    );
    if (clash) throw const CategoryException(CategoryProblem.duplicateName);

    final existing = sameType.where((c) => c.id == category.id).firstOrNull;
    final saved = TransactionCategory(
      id: category.id.isEmpty ? newId() : category.id,
      name: name,
      icon: category.icon,
      color: category.id.isEmpty
          ? _palette[sameType.length % _palette.length]
          : category.color,
      type: category.type,
    );
    final now = _clock();
    await _db.transaction(() async {
      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            saved.toCompanion(
              modifiedAt: now,
              sortOrder: existing?.sortOrder ?? sameType.length,
            ),
          );
      if (existing != null &&
          (existing.name != saved.name || existing.icon != saved.icon)) {
        await _refile(existing.toDomain(), saved, now);
      }
    });
    return saved;
  });

  /// Moves the transactions and budgets filed under [from] to [to], so
  /// past spending follows a renamed category.
  Future<void> _refile(
    TransactionCategory from,
    TransactionCategory to,
    DateTime now,
  ) async {
    await (_db.update(_db.transactions)..where(
          (t) =>
              t.categoryName.equals(from.name) &
              t.type.equals(from.type.name) &
              t.deleted.equals(false),
        ))
        .write(
          TransactionsCompanion(
            categoryName: Value(to.name),
            categoryIcon: Value(to.icon),
            categoryColor: Value(to.color),
            modifiedAt: Value(now),
            dirty: const Value(true),
          ),
        );
    if (from.type != TransactionType.expense) return;
    await (_db.update(_db.budgets)..where(
          (b) => b.categoryName.equals(from.name) & b.deleted.equals(false),
        ))
        .write(
          BudgetsCompanion(
            categoryName: Value(to.name),
            categoryIcon: Value(to.icon),
            categoryColor: Value(to.color),
            modifiedAt: Value(now),
            dirty: const Value(true),
          ),
        );
  }

  @override
  Future<Result<void>> deleteCategory(String id) => guard(() async {
    if (CategoryRepository.protectedIds.contains(id)) {
      throw const CategoryException(CategoryProblem.protected);
    }
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    final sameType = await _live(type: TransactionType.values.byName(row.type))
        .get();
    if (sameType.length <= 1) {
      throw const CategoryException(CategoryProblem.lastOfType);
    }
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });

  @override
  Future<Result<void>> reorderCategories(
    TransactionType type,
    List<String> orderedIds,
  ) => guard(() async {
    final rows = await _live(type: type).get();
    int rank(CategoryRow c) {
      final i = orderedIds.indexOf(c.id);
      return i < 0 ? orderedIds.length : i;
    }

    final sorted = [...rows]..sort((a, b) => rank(a).compareTo(rank(b)));
    final now = _clock();
    await _db.batch((batch) {
      for (final (i, row) in sorted.indexed) {
        if (row.sortOrder == i) continue;
        batch.update(
          _db.categories,
          CategoriesCompanion(
            sortOrder: Value(i),
            dirty: const Value(true),
            modifiedAt: Value(now),
          ),
          where: (c) => c.id.equals(row.id),
        );
      }
    });
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
