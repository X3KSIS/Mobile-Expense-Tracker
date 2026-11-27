import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_store.dart';

/// [RemoteStore] on Supabase's REST API. Row-level security limits every
/// call to the signed-in user's rows.
class SupabaseRemoteStore implements RemoteStore {
  SupabaseRemoteStore(this._client);

  final SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    required DateTime since,
    int limit = 500,
  }) => _client
      .from(table)
      .select()
      .gt('updated_at', since.toUtc().toIso8601String())
      .order('updated_at', ascending: true)
      .limit(limit);

  @override
  Future<void> push(String table, List<Map<String, dynamic>> rows) =>
      _client.from(table).upsert(rows, onConflict: 'user_id,id');

  @override
  Future<Map<String, dynamic>?> pullProfile() async {
    final id = userId;
    if (id == null) return null;
    return _client.from('profiles').select().eq('user_id', id).maybeSingle();
  }

  @override
  Future<void> pushProfile(Map<String, dynamic> values) async {
    final id = userId;
    if (id == null) return;
    await _client.from('profiles').update(values).eq('user_id', id);
  }
}
