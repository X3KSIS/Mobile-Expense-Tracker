import 'package:drift/drift.dart';

import '../../../domain/models/account_link.dart';
import '../../../domain/models/detected_payment.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/provider_api/provider_api_service.dart';
import 'account_link_repository.dart';

/// [AccountLinkRepository] backed by institution APIs.
///
/// [services] is empty until an institution grants API access, so nothing
/// can be linked yet. With a [database], links are stored and synced;
/// without one (tests) they live in memory.
class AccountLinkRepositoryApi extends AccountLinkRepository {
  AccountLinkRepositoryApi({
    List<ProviderApiService> services = const [],
    AppDatabase? database,
    DateTime Function()? clock,
  }) : _services = {for (final s in services) s.providerName: s},
       _db = database,
       _clock = clock ?? DateTime.now {
    _restore();
  }

  final Map<String, ProviderApiService> _services;
  final AppDatabase? _db;
  final DateTime Function() _clock;
  final Map<String, AccountLink> _links = {};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _restore() async {
    final db = _db;
    if (db == null) return;
    final rows = await (db.select(
      db.accountLinks,
    )..where((l) => l.deleted.equals(false))).get();
    if (_disposed) return;
    for (final row in rows) {
      _links.putIfAbsent(row.id, row.toDomain);
    }
    if (rows.isNotEmpty) notifyListeners();
  }

  Future<void> _store(AccountLink link) async {
    final db = _db;
    if (db == null) return;
    await db
        .into(db.accountLinks)
        .insertOnConflictUpdate(link.toCompanion(modifiedAt: _clock()));
  }

  @override
  List<String> get availableProviders => _services.keys.toList()..sort();

  @override
  List<AccountLink> get links => _links.values.toList(growable: false);

  @override
  AccountLink? linkFor(String walletId) => _links[walletId];

  @override
  Future<Result<AccountLink>> link({
    required String walletId,
    required String providerName,
    required String accountRef,
  }) async {
    if (!_services.containsKey(providerName)) {
      return Result.error(Exception("$providerName can't be connected yet"));
    }
    final ref = accountRef.trim();
    if (ref.isEmpty) {
      return Result.error(Exception('Enter the account or phone number'));
    }
    final link = AccountLink(
      walletId: walletId,
      providerName: providerName,
      accountRef: ref,
    );
    _links[walletId] = link;
    notifyListeners();
    return guard(() async {
      await _store(link);
      return link;
    });
  }

  @override
  Future<Result<void>> unlink(String walletId) => guard(() async {
    if (_links.remove(walletId) != null) notifyListeners();
    final db = _db;
    if (db == null) return;
    await (db.update(
      db.accountLinks,
    )..where((l) => l.id.equals(walletId))).write(
      AccountLinksCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });

  @override
  Future<Result<List<DetectedPayment>>> sync(String walletId) async {
    final link = _links[walletId];
    if (link == null) {
      return Result.error(Exception('This wallet is not connected'));
    }
    final service = _services[link.providerName];
    if (service == null) {
      return Result.error(
        Exception("${link.providerName} can't be connected yet"),
      );
    }
    final now = _clock();
    final since =
        link.lastSyncedAt ??
        now.subtract(const Duration(days: AccountLinkRepository.firstSyncDays));
    final result = await service.fetchTransactions(
      accountRef: link.accountRef,
      since: since,
    );
    switch (result) {
      case Ok(:final value):
        final synced = link.copyWith(lastSyncedAt: now);
        _links[walletId] = synced;
        notifyListeners();
        await _store(synced);
        return Result.ok([
          for (final (i, message) in value.indexed)
            DetectedPayment(
              // The reference matches the one in the SMS for the same
              // payment, so it is only offered once.
              id:
                  message.reference ??
                  '${link.providerName}:${now.millisecondsSinceEpoch}:$i',
              message: message,
              receivedAt: message.date ?? now,
              sender: link.providerName,
            ),
        ]);
      case Error(:final error):
        return Result.error(error);
    }
  }
}
