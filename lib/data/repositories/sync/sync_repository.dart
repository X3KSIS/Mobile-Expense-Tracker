import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';

/// Where syncing with the server stands.
enum SyncStatus {
  /// Nothing to do right now; everything changed here has been sent.
  idle,

  /// Sending and fetching changes.
  syncing,

  /// The last attempt failed (usually no connection); it will retry.
  failed,

  /// Nobody is signed in, or there is no server, so nothing syncs.
  off,
}

/// Keeps the on-device database in step with the server.
///
/// Changes are always saved on the phone first, so the app works offline;
/// this sends them up and brings other devices' changes down. When the
/// same record was changed in two places, the later change wins.
abstract class SyncRepository extends ChangeNotifier {
  SyncStatus get status;

  /// When the last sync finished without errors, or null.
  DateTime? get lastSyncedAt;

  /// Sends local changes and fetches remote ones now.
  Future<Result<void>> sync();

  /// Starts syncing automatically: after local changes, on a timer and
  /// after failures. Call when the user signs in.
  void start();

  /// Stops automatic syncing. Call when the user signs out.
  void stop();
}
