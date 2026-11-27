import 'package:flutter_expensetracker/data/services/sync/remote_store.dart';

/// An in-memory server with the same rules as the Supabase migration:
/// rows keyed by user and id, the later `modified_at` wins, and every
/// stored row gets a fresh server `updated_at`.
class FakeRemoteStore implements RemoteStore {
  FakeRemoteStore({this.userId = 'user-1'});

  @override
  String? userId;

  /// table → id → row.
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  Map<String, dynamic>? profile;

  /// Set to make every call fail, like a lost connection.
  bool offline = false;

  int pushes = 0;
  DateTime _serverClock = DateTime.utc(2026, 11, 27, 8);

  String _stamp() {
    _serverClock = _serverClock.add(const Duration(milliseconds: 1));
    return _serverClock.toIso8601String();
  }

  void _check() {
    if (offline) throw Exception('No connection');
  }

  /// Stores [row] as another device would.
  void seed(String table, Map<String, dynamic> row) =>
      _store(table, {'user_id': userId, ...row});

  void _store(String table, Map<String, dynamic> row) {
    final rows = tables.putIfAbsent(table, () => {});
    final existing = rows[row['id']];
    if (existing != null &&
        DateTime.parse(row['modified_at'] as String)
            .isBefore(DateTime.parse(existing['modified_at'] as String))) {
      return;
    }
    rows[row['id'] as String] = {...row, 'updated_at': _stamp()};
  }

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    required DateTime since,
    int limit = 500,
  }) async {
    _check();
    final rows =
        (tables[table]?.values ?? const <Map<String, dynamic>>[])
            .where(
              (r) => DateTime.parse(r['updated_at'] as String).isAfter(since),
            )
            .toList()
          ..sort(
            (a, b) => (a['updated_at'] as String).compareTo(
              b['updated_at'] as String,
            ),
          );
    return [for (final r in rows.take(limit)) Map.of(r)];
  }

  @override
  Future<void> push(String table, List<Map<String, dynamic>> rows) async {
    _check();
    pushes++;
    for (final row in rows) {
      _store(table, row);
    }
  }

  @override
  Future<Map<String, dynamic>?> pullProfile() async {
    _check();
    return profile == null ? null : Map.of(profile!);
  }

  @override
  Future<void> pushProfile(Map<String, dynamic> values) async {
    _check();
    final current = profile;
    if (current != null &&
        DateTime.parse(values['modified_at'] as String)
            .isBefore(DateTime.parse(current['modified_at'] as String))) {
      return;
    }
    profile = {...?current, ...values, 'updated_at': _stamp()};
  }
}
