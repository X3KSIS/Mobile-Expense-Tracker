import 'dart:async';

import 'package:drift/drift.dart';

import '../../../domain/models/detected_payment.dart';
import '../../../utils/money_message_parser.dart';
import '../../../utils/result.dart';
import '../../services/database/app_database.dart';
import '../../services/database/mappers.dart';
import '../../services/notification_listener_client.dart';
import 'detected_payment_repository.dart';

/// [DetectedPaymentRepository] fed by the phone's notifications.
///
/// Only notifications that read as a payment confirmation and name a
/// provider (MTN, Airtel, Zamtel, a bank or an account) are kept, so chat
/// messages mentioning money are ignored. The notification text itself
/// stays on the phone; the details read from it (amount, other party,
/// reference) are stored in the database and synced, so a payment added
/// or dismissed on one device is not offered again on another.
class DetectedPaymentRepositoryNotifications extends DetectedPaymentRepository {
  DetectedPaymentRepositoryNotifications(
    this._db, {
    this.client = const NotificationListenerClient(),
    this.ownPackage = 'com.example.flutter_expensetracker',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _tableUpdates = _db
        .tableUpdates(TableUpdateQuery.onTable(_db.detectedPayments))
        .listen((_) => _restore());
    // Payments waiting from before (or from another device) show even
    // while notification access is off.
    _restore();
  }

  final AppDatabase _db;
  final NotificationListenerClient client;
  final DateTime Function() _clock;

  /// This app's package, whose own notifications are skipped.
  final String ownPackage;

  final Map<String, DetectedPayment> _pending = {};

  /// Ids added or dismissed, so a notification still in the tray is not
  /// offered again.
  final Set<String> _handled = {};
  StreamSubscription<PostedNotification>? _subscription;
  late final StreamSubscription<Set<TableUpdate>> _tableUpdates;
  bool _enabled = false;
  bool _restored = false;
  bool _disposed = false;

  @override
  bool get isSupported => client.isSupported;

  @override
  bool get isEnabled => _enabled;

  @override
  List<DetectedPayment> get pending =>
      _pending.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  /// Loads pending and handled payments from the database.
  Future<void> _restore() async {
    final rows = await (_db.select(
      _db.detectedPayments,
    )..where((p) => p.deleted.equals(false))).get();
    if (_disposed) return;
    _pending.clear();
    _handled.clear();
    for (final row in rows) {
      if (row.status == 'pending') {
        _pending[row.id] = row.toDomain();
      } else {
        _handled.add(row.id);
      }
    }
    _restored = true;
    notifyListeners();
  }

  @override
  Future<Result<void>> refresh() async {
    try {
      if (!_restored) await _restore();
      final enabled = await client.isPermissionGranted();
      final changed = enabled != _enabled;
      _enabled = enabled;
      if (!enabled) {
        await _subscription?.cancel();
        _subscription = null;
        if (changed) notifyListeners();
        return const Result.ok(null);
      }
      _subscription ??= client.notifications.listen(_onNotification);
      var added = false;
      for (final n in await client.active()) {
        added = await _take(n) || added;
      }
      if (added || changed) notifyListeners();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<bool>> enable() async {
    try {
      if (!await client.isPermissionGranted()) {
        await client.requestPermission();
      }
      final result = await refresh();
      return switch (result) {
        Ok() => Result.ok(_enabled),
        Error(:final error) => Result.error(error),
      };
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<void>> markAdded(String id) => _resolve(id, 'added');

  @override
  Future<Result<void>> dismiss(String id) => _resolve(id, 'dismissed');

  Future<Result<void>> _resolve(String id, String status) => guard(() async {
    _handled.add(id);
    if (_pending.remove(id) != null) notifyListeners();
    await (_db.update(
      _db.detectedPayments,
    )..where((p) => p.id.equals(id))).write(
      DetectedPaymentsCompanion(
        status: Value(status),
        dirty: const Value(true),
        modifiedAt: Value(_clock()),
      ),
    );
  });

  Future<void> _onNotification(PostedNotification n) async {
    if (await _take(n)) notifyListeners();
  }

  /// Keeps [n] if it is a new payment message. Returns whether it was.
  Future<bool> _take(PostedNotification n) async {
    if (n.removed || n.packageName == ownPackage) return false;
    final text = [n.title, n.content].where((s) => s.isNotEmpty).join('. ');
    final message = MoneyMessageParser.parse(text);
    if (message == null || message.provider == null) return false;
    final id = message.reference ?? '${n.packageName}:${n.content.hashCode}';
    if (_handled.contains(id) || _pending.containsKey(id)) return false;
    final payment = DetectedPayment(
      id: id,
      message: message,
      receivedAt: n.postedAt,
      sender: n.title.isEmpty ? null : n.title,
    );
    _pending[id] = payment;
    await _db
        .into(_db.detectedPayments)
        .insert(
          payment.toCompanion(modifiedAt: _clock()),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _tableUpdates.cancel();
    super.dispose();
  }
}
