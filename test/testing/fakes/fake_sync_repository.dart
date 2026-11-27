import 'package:flutter_expensetracker/data/repositories/sync/sync_repository.dart';
import 'package:flutter_expensetracker/utils/result.dart';

/// A [SyncRepository] that records calls and never talks to a server.
class FakeSyncRepository extends SyncRepository {
  bool running = false;
  int syncs = 0;

  @override
  SyncStatus get status => running ? SyncStatus.idle : SyncStatus.off;

  @override
  DateTime? get lastSyncedAt => null;

  @override
  Future<Result<void>> sync() async {
    syncs++;
    return const Result.ok(null);
  }

  @override
  void start() => running = true;

  @override
  void stop() => running = false;
}
