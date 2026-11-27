import 'package:drift/drift.dart';

import '../../../domain/models/transfer.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/ids.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/database/table_watcher.dart';
import 'wallet_repository.dart';

/// [WalletRepository] stored in the on-device database and synced to
/// Supabase.
class WalletRepositoryDrift extends WalletRepository with TableWatcher {
  WalletRepositoryDrift(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    watchTables(_db, [_db.wallets, _db.transfers]);
  }

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// The Cash wallet every account starts with, as the server seeds it.
  static const Wallet cash = Wallet(
    id: 'w-cash',
    name: 'Cash',
    kind: WalletKind.cash,
  );

  Future<List<WalletRow>> _rows() =>
      (_db.select(_db.wallets)
            ..where((w) => w.deleted.equals(false))
            ..orderBy([
              (w) => OrderingTerm.asc(w.sortOrder),
              (w) => OrderingTerm.asc(w.modifiedAt),
            ]))
          .get();

  @override
  Future<Result<List<Wallet>>> getWallets() => guard(() async {
    await _seedIfEmpty();
    return [for (final r in await _rows()) r.toDomain()];
  });

  /// A new device has the Cash wallet before its first sync. Seeded as
  /// old and clean, so the server's copy wins.
  Future<void> _seedIfEmpty() async {
    final count = await _db.wallets.count().getSingle();
    if (count > 0) return;
    await _db
        .into(_db.wallets)
        .insert(
          cash.toCompanion(
            modifiedAt: DateTime.utc(2000),
            sortOrder: 0,
            dirty: false,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<Result<Wallet>> saveWallet(Wallet wallet) => guard(() async {
    final saved = wallet.id.isEmpty
        ? Wallet(
            id: newId(),
            name: wallet.name,
            kind: wallet.kind,
            openingBalance: wallet.openingBalance,
          )
        : wallet;
    final existing = await (_db.select(
      _db.wallets,
    )..where((w) => w.id.equals(saved.id))).getSingleOrNull();
    final sortOrder = existing?.sortOrder ?? (await _rows()).length;
    await _db
        .into(_db.wallets)
        .insertOnConflictUpdate(
          saved.toCompanion(modifiedAt: _clock(), sortOrder: sortOrder),
        );
    return saved;
  });

  @override
  Future<Result<List<Transfer>>> getTransfers() => guard(() async {
    final rows =
        await (_db.select(_db.transfers)
              ..where((t) => t.deleted.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return [for (final r in rows) r.toDomain()];
  });

  @override
  Future<Result<Transfer>> addTransfer(Transfer transfer) => guard(() async {
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw Exception('Pick two different wallets');
    }
    final saved = transfer.id.isEmpty
        ? Transfer(
            id: newId(),
            fromWalletId: transfer.fromWalletId,
            toWalletId: transfer.toWalletId,
            amount: transfer.amount,
            date: transfer.date,
            note: transfer.note,
          )
        : transfer;
    await _db
        .into(_db.transfers)
        .insertOnConflictUpdate(saved.toCompanion(modifiedAt: _clock()));
    return saved;
  });

  @override
  Future<Result<void>> deleteTransfer(String id) => guard(() async {
    await (_db.update(_db.transfers)..where((t) => t.id.equals(id))).write(
      TransfersCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });
}
