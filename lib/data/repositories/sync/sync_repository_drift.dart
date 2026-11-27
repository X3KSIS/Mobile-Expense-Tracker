import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/sync/remote_store.dart';
import '../../services/sync/sync_serializer.dart';
import 'sync_repository.dart';

/// [SyncRepository] between the Drift database and a [RemoteStore]
/// (Supabase).
///
/// Push: rows marked dirty are sent, then marked clean unless they were
/// changed again meanwhile. Pull: rows the server stored after the last
/// pull are applied, except where this device holds a newer unsent edit.
class SyncRepositoryDrift extends SyncRepository {
  SyncRepositoryDrift(
    this._db,
    this._remote, {
    this.debounce = const Duration(seconds: 2),
    this.interval = const Duration(minutes: 5),
    this.retryAfter = const Duration(minutes: 1),
  }) {
    _tables = [
      _SyncTable<$CategoriesTable, CategoryRow>(
        _db.categories,
        'categories',
        CategoryRow.fromJson,
      ),
      _SyncTable<$WalletsTable, WalletRow>(
        _db.wallets,
        'wallets',
        WalletRow.fromJson,
      ),
      _SyncTable<$TransfersTable, TransferRow>(
        _db.transfers,
        'transfers',
        TransferRow.fromJson,
      ),
      _SyncTable<$TransactionsTable, TransactionRow>(
        _db.transactions,
        'transactions',
        TransactionRow.fromJson,
      ),
      _SyncTable<$BudgetsTable, BudgetRow>(
        _db.budgets,
        'budgets',
        BudgetRow.fromJson,
      ),
      _SyncTable<$DetectedPaymentsTable, DetectedPaymentRow>(
        _db.detectedPayments,
        'detected_payments',
        DetectedPaymentRow.fromJson,
        jsonColumn: 'message',
      ),
      _SyncTable<$AccountLinksTable, AccountLinkRow>(
        _db.accountLinks,
        'account_links',
        AccountLinkRow.fromJson,
      ),
    ];
  }

  final AppDatabase _db;
  final RemoteStore _remote;

  /// Wait this long after a local change before syncing, so a burst of
  /// edits goes up together.
  final Duration debounce;

  /// Fetch other devices' changes this often while running.
  final Duration interval;

  /// Try again this long after a failure.
  final Duration retryAfter;

  static const int _pageSize = 500;
  static const SyncSerializer _serializer = SyncSerializer();

  late final List<_SyncTable<Table, DataClass>> _tables;

  SyncStatus _status = SyncStatus.off;
  DateTime? _lastSyncedAt;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;
  Future<Result<void>>? _inFlight;
  StreamSubscription<Set<TableUpdate>>? _localChanges;
  Timer? _debounceTimer;
  Timer? _periodic;
  Timer? _retry;

  @override
  SyncStatus get status => _status;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  void start() {
    if (_running) return;
    _running = true;
    _localChanges = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            for (final t in _tables) t.table,
            _db.profiles,
          ]),
        )
        .listen((_) => _schedule());
    _periodic = Timer.periodic(interval, (_) => sync());
    sync();
  }

  @override
  void stop() {
    _running = false;
    _localChanges?.cancel();
    _localChanges = null;
    _debounceTimer?.cancel();
    _periodic?.cancel();
    _retry?.cancel();
    _setStatus(SyncStatus.off);
  }

  void _schedule() {
    if (!_running) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, sync);
  }

  @override
  Future<Result<void>> sync() {
    if (_remote.userId == null) {
      _setStatus(SyncStatus.off);
      return Future.value(const Result.ok(null));
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      // Changes made during this round go up in the next one.
      _again = true;
      return inFlight;
    }
    return _inFlight = _run();
  }

  Future<Result<void>> _run() async {
    _retry?.cancel();
    _setStatus(SyncStatus.syncing);
    final result = await guard(() async {
      for (final table in _tables) {
        await _push(table);
      }
      await _pushProfile();
      for (final table in _tables) {
        await _pull(table);
      }
      await _pullProfile();
    });
    _inFlight = null;
    if (_disposed) return result;
    switch (result) {
      case Ok():
        _lastSyncedAt = DateTime.now();
        _setStatus(SyncStatus.idle);
        if (_again) {
          _again = false;
          _schedule();
        }
      case Error():
        _setStatus(SyncStatus.failed);
        if (_running) _retry = Timer(retryAfter, sync);
    }
    return result;
  }

  // -------------------------------------------------------------------
  // Tables
  // -------------------------------------------------------------------

  Future<void> _push(_SyncTable t) async {
    final rows = await t.dirtyRows(_db);
    if (rows.isEmpty) return;
    final userId = _remote.userId!;
    for (var i = 0; i < rows.length; i += _pageSize) {
      final page = rows.skip(i).take(_pageSize).toList();
      await _remote.push(t.name, [
        for (final row in page) t.toRemote(row, userId),
      ]);
      await t.markClean(_db, page);
    }
  }

  Future<void> _pull(_SyncTable t) async {
    var since = await _cursor(t.name);
    while (true) {
      final rows = await _remote.pull(t.name, since: since, limit: _pageSize);
      if (rows.isEmpty) return;
      await _db.transaction(() async {
        for (final remote in rows) {
          await t.apply(_db, remote);
        }
        since = DateTime.parse(rows.last['updated_at'] as String);
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(
                tableName_: t.name,
                pulledUpTo: since,
              ),
            );
      });
      if (rows.length < _pageSize) return;
    }
  }

  Future<DateTime> _cursor(String table) async {
    final row = await (_db.select(
      _db.syncCursors,
    )..where((c) => c.tableName_.equals(table))).getSingleOrNull();
    return row?.pulledUpTo ?? DateTime.utc(1970);
  }

  // -------------------------------------------------------------------
  // Profile and settings
  // -------------------------------------------------------------------

  Future<ProfileRow?> _localProfile() => (_db.select(
    _db.profiles,
  )..where((p) => p.userId.equals(_remote.userId!))).getSingleOrNull();

  /// Uploads a new photo (or removes a cleared one) before the profile
  /// goes up, so the profile points at a file that exists. Each upload
  /// gets a new name, so other devices notice the change.
  Future<void> _pushPhoto() async {
    final local = await _localProfile();
    if (local == null || !local.avatarDirty) return;
    final userId = _remote.userId!;
    final bytes = local.avatarBytes;
    final previous = local.avatarPath;
    String? path;
    if (bytes != null) {
      path = '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _remote.uploadPhoto(path, bytes);
    }
    await (_db.update(_db.profiles)..where(
          (p) =>
              p.userId.equals(local.userId) &
              p.modifiedAt.equals(local.modifiedAt),
        ))
        .write(
          ProfilesCompanion(
            avatarPath: Value(path),
            avatarDirty: const Value(false),
            dirty: const Value(true),
          ),
        );
    if (previous != null && previous != path) {
      try {
        await _remote.deletePhoto(previous);
      } on Exception {
        // An old file left behind does no harm.
      }
    }
  }

  Future<void> _pushProfile() async {
    await _pushPhoto();
    final local = await _localProfile();
    if (local == null || !local.dirty) return;
    await _remote.pushProfile({
      'name': local.name,
      'phone': local.phone,
      'payday': local.payday,
      'theme': local.theme,
      'budget_alert_percent': local.budgetAlertPercent,
      'default_wallet_id': local.defaultWalletId,
      'show_habits': local.showHabits,
      'hide_amounts': local.hideAmounts,
      'avatar_path': local.avatarPath,
      'modified_at': _serializer.toJson(local.modifiedAt),
    });
    await (_db.update(_db.profiles)..where(
          (p) =>
              p.userId.equals(local.userId) &
              p.modifiedAt.equals(local.modifiedAt),
        ))
        .write(const ProfilesCompanion(dirty: Value(false)));
  }

  Future<void> _pullProfile() async {
    final remote = await _remote.pullProfile();
    final local = await _localProfile();
    if (remote == null || local == null) return;
    final remoteModified = DateTime.parse(remote['modified_at'] as String)
        .toLocal();
    if (local.dirty && local.modifiedAt.isAfter(remoteModified)) return;
    final name = remote['name'] as String? ?? '';
    final phone = remote['phone'] as String?;
    final payday = (remote['payday'] as num?)?.toInt() ?? 1;
    final theme = remote['theme'] as String? ?? 'system';
    final alert = (remote['budget_alert_percent'] as num?)?.toInt() ?? 80;
    final wallet = remote['default_wallet_id'] as String?;
    final showHabits = remote['show_habits'] as bool? ?? true;
    final hideAmounts = remote['hide_amounts'] as bool? ?? false;
    final avatarPath = remote['avatar_path'] as String?;
    final photoChanged = !local.avatarDirty && avatarPath != local.avatarPath;
    final unchanged =
        !local.dirty &&
        local.name == name &&
        local.phone == phone &&
        local.payday == payday &&
        local.theme == theme &&
        local.budgetAlertPercent == alert &&
        local.defaultWalletId == wallet &&
        local.showHabits == showHabits &&
        local.hideAmounts == hideAmounts &&
        !photoChanged &&
        local.modifiedAt.isAtSameMomentAs(remoteModified);
    // Writing anyway would wake the change watcher and sync again forever.
    if (unchanged) return;
    await (_db.update(
      _db.profiles,
    )..where((p) => p.userId.equals(local.userId))).write(
      ProfilesCompanion(
        name: Value(name),
        phone: Value(phone),
        payday: Value(payday),
        theme: Value(theme),
        budgetAlertPercent: Value(alert),
        defaultWalletId: Value(wallet),
        showHabits: Value(showHabits),
        hideAmounts: Value(hideAmounts),
        avatarPath: photoChanged ? Value(avatarPath) : const Value.absent(),
        avatarBytes: photoChanged
            ? Value(
                avatarPath == null
                    ? null
                    : await _remote.downloadPhoto(avatarPath),
              )
            : const Value.absent(),
        modifiedAt: Value(remoteModified),
        dirty: const Value(false),
      ),
    );
  }

  void _setStatus(SyncStatus status) {
    if (_disposed || status == _status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}

/// One synced table: its Drift table, server name and row conversions.
class _SyncTable<T extends Table, R extends DataClass> {
  _SyncTable(this.table, this.name, this._fromJson, {this.jsonColumn});

  final TableInfo<T, R> table;
  final String name;
  final R Function(Map<String, dynamic> json, {ValueSerializer? serializer})
  _fromJson;

  /// A column kept as JSON text here and as `jsonb` on the server.
  final String? jsonColumn;

  static const SyncSerializer _serializer = SyncSerializer();

  GeneratedColumn<String> get _id =>
      table.columnsByName['id']! as GeneratedColumn<String>;
  GeneratedColumn<bool> get _dirty =>
      table.columnsByName['dirty']! as GeneratedColumn<bool>;
  GeneratedColumn<DateTime> get _modifiedAt =>
      table.columnsByName['modified_at']! as GeneratedColumn<DateTime>;

  Map<String, Expression> _columns(R row) =>
      (row as Insertable<R>).toColumns(false);

  String _idOf(R row) => (_columns(row)['id']! as Variable<String>).value!;

  DateTime _modifiedAtOf(R row) =>
      (_columns(row)['modified_at']! as Variable<DateTime>).value!;

  bool _isDirty(R row) =>
      (_columns(row)['dirty']! as Variable<bool>).value ?? false;

  Future<List<R>> dirtyRows(AppDatabase db) =>
      (db.select(table)..where((_) => _dirty.equals(true))).get();

  /// Marks [rows] clean, except those changed again since they were read.
  Future<void> markClean(AppDatabase db, List<R> rows) => db.batch((batch) {
    for (final row in rows) {
      batch.update(
        table,
        RawValuesInsertable<R>({'dirty': const Constant(false)}),
        where: (_) =>
            _id.equals(_idOf(row)) & _modifiedAt.equals(_modifiedAtOf(row)),
      );
    }
  });

  /// Stores the server's [remote] row, unless this device holds a newer
  /// unsent edit of it (which goes up on the next push).
  Future<void> apply(AppDatabase db, Map<String, dynamic> remote) async {
    final local = await (db.select(
      table,
    )..where((_) => _id.equals(remote['id'] as String))).getSingleOrNull();
    if (local != null && _isDirty(local)) {
      final remoteModified = DateTime.parse(remote['modified_at'] as String);
      if (_modifiedAtOf(local).isAfter(remoteModified)) return;
    }
    await db
        .into(table)
        .insertOnConflictUpdate(fromRemote(remote) as Insertable<R>);
  }

  /// The row as the server stores it.
  Map<String, dynamic> toRemote(R row, String userId) {
    final json = row.toJson(serializer: _serializer);
    final out = <String, dynamic>{'user_id': userId};
    for (final MapEntry(:key, :value) in json.entries) {
      if (key == 'dirty') continue;
      final column = snakeCase(key);
      out[column] = column == jsonColumn && value is String
          ? jsonDecode(value)
          : value;
    }
    return out;
  }

  /// The server's row as a local row, clean.
  R fromRemote(Map<String, dynamic> remote) {
    final json = <String, dynamic>{'dirty': false};
    for (final MapEntry(:key, :value) in remote.entries) {
      if (key == 'user_id' || key == 'updated_at') continue;
      json[camelCase(key)] = key == jsonColumn && value is! String
          ? jsonEncode(value)
          : value;
    }
    return _fromJson(json, serializer: _serializer);
  }
}
