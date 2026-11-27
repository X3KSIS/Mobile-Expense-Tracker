/// The server side of sync: one user's rows in the backend's tables.
///
/// Rows are JSON maps with the server's snake_case column names. Dates
/// are ISO 8601 strings in UTC. `SupabaseRemoteStore` is the real one.
abstract class RemoteStore {
  /// The signed-in user's id, or null when signed out.
  String? get userId;

  /// Rows of [table] stored after [since] (by `updated_at`), oldest first,
  /// at most [limit] of them.
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    required DateTime since,
    int limit = 500,
  });

  /// Inserts or updates [rows] in [table]. The server keeps whichever
  /// version has the later `modified_at`.
  Future<void> push(String table, List<Map<String, dynamic>> rows);

  /// The signed-in user's profile row, or null.
  Future<Map<String, dynamic>?> pullProfile();

  /// Updates the signed-in user's profile with [values].
  Future<void> pushProfile(Map<String, dynamic> values);
}
