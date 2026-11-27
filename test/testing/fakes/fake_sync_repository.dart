import 'package:flutter_expensetracker/data/repositories/sync/sync_repository.dart';
import 'package:flutter_expensetracker/utils/result.dart';

/// A [SyncRepository] that records calls and never talks to a server.
/// Set [status] and [lastSyncedAt] to show a state.
class FakeSyncRepository extends SyncRepository {
  bool running = false;
  int syncs = 0;

  SyncStatus _status = SyncStatus.off;
  DateTime? _lastSyncedAt;

  @override
  SyncStatus get status => _status;

  set status(SyncStatus value) {
    _status = value;
    notifyListeners();
  }

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  set lastSyncedAt(DateTime? value) {
    _lastSyncedAt = value;
    notifyListeners();
  }

  @override
  Future<Result<void>> sync() async {
    syncs++;
    return const Result.ok(null);
  }

  @override
  void start() {
    running = true;
    status = SyncStatus.idle;
  }

  @override
  void stop() {
    running = false;
    status = SyncStatus.off;
  }
}
