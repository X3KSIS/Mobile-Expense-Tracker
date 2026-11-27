import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Notifies listeners whenever any of the watched tables change, whether
/// the change was made here or arrived through sync.
mixin TableWatcher on ChangeNotifier {
  StreamSubscription<Set<TableUpdate>>? _tableUpdates;

  void watchTables(AppDatabase database, List<TableInfo> tables) {
    _tableUpdates = database
        .tableUpdates(TableUpdateQuery.onAllTables(tables))
        .listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _tableUpdates?.cancel();
    super.dispose();
  }
}
