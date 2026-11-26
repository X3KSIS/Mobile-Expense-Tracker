import 'dart:async';

import '../../../domain/models/detected_payment.dart';
import '../../../utils/money_message_parser.dart';
import '../../../utils/result.dart';
import '../../services/notification_listener_client.dart';
import 'detected_payment_repository.dart';

/// [DetectedPaymentRepository] fed by the phone's notifications.
///
/// Only notifications that read as a payment confirmation and name a
/// provider (MTN, Airtel, Zamtel, a bank or an account) are kept, so chat
/// messages mentioning money are ignored. The text never leaves the phone.
/// Pending payments live in memory until local storage (Drift) is added.
class DetectedPaymentRepositoryNotifications extends DetectedPaymentRepository {
  DetectedPaymentRepositoryNotifications({
    this.client = const NotificationListenerClient(),
    this.ownPackage = 'com.example.flutter_expensetracker',
  });

  final NotificationListenerClient client;

  /// This app's package, whose own notifications are skipped.
  final String ownPackage;

  final Map<String, DetectedPayment> _pending = {};

  /// Ids added or dismissed, so a notification still in the tray is not
  /// offered again.
  final Set<String> _handled = {};
  StreamSubscription<PostedNotification>? _subscription;
  bool _enabled = false;

  @override
  bool get isSupported => client.isSupported;

  @override
  bool get isEnabled => _enabled;

  @override
  List<DetectedPayment> get pending =>
      _pending.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  @override
  Future<Result<void>> refresh() async {
    try {
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
        added = _take(n) || added;
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
  Future<Result<void>> markAdded(String id) => _remove(id);

  @override
  Future<Result<void>> dismiss(String id) => _remove(id);

  Future<Result<void>> _remove(String id) async {
    _handled.add(id);
    if (_pending.remove(id) != null) notifyListeners();
    return const Result.ok(null);
  }

  void _onNotification(PostedNotification n) {
    if (_take(n)) notifyListeners();
  }

  /// Keeps [n] if it is a new payment message. Returns whether it was.
  bool _take(PostedNotification n) {
    if (n.removed || n.packageName == ownPackage) return false;
    final text = [n.title, n.content].where((s) => s.isNotEmpty).join('. ');
    final message = MoneyMessageParser.parse(text);
    if (message == null || message.provider == null) return false;
    final id = message.reference ?? '${n.packageName}:${n.content.hashCode}';
    if (_handled.contains(id) || _pending.containsKey(id)) return false;
    _pending[id] = DetectedPayment(
      id: id,
      message: message,
      receivedAt: n.postedAt,
      sender: n.title.isEmpty ? null : n.title,
    );
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
