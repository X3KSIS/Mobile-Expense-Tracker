import '../../../domain/models/detected_payment.dart';
import '../../../utils/money_message_parser.dart';
import '../../../utils/result.dart';
import 'detected_payment_repository.dart';

/// In-memory [DetectedPaymentRepository] for tests and devices without
/// notification access. [enable] turns access on and offers the
/// [incoming] messages, as if they had just arrived.
class DetectedPaymentRepositoryLocalFake extends DetectedPaymentRepository {
  DetectedPaymentRepositoryLocalFake({
    this.isSupported = true,
    bool enabled = false,
    this.incoming = const [],
    DateTime? now,
  }) : _enabled = enabled,
       _now = now ?? DateTime.now() {
    if (enabled) _receive();
  }

  @override
  final bool isSupported;

  /// SMS texts that "arrive" once access is on.
  final List<String> incoming;
  final DateTime _now;

  bool _enabled;
  final Map<String, DetectedPayment> _pending = {};
  final Set<String> _handled = {};

  @override
  bool get isEnabled => _enabled;

  @override
  List<DetectedPayment> get pending =>
      _pending.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  @override
  Future<Result<void>> refresh() async => const Result.ok(null);

  @override
  Future<Result<bool>> enable() async {
    if (!isSupported) return const Result.ok(false);
    _enabled = true;
    _receive();
    notifyListeners();
    return const Result.ok(true);
  }

  @override
  Future<Result<void>> markAdded(String id) => dismiss(id);

  @override
  Future<Result<void>> dismiss(String id) async {
    _handled.add(id);
    if (_pending.remove(id) != null) notifyListeners();
    return const Result.ok(null);
  }

  void _receive() {
    for (final (i, text) in incoming.indexed) {
      final message = MoneyMessageParser.parse(text);
      if (message == null) continue;
      final id = message.reference ?? 'fake-$i';
      if (_handled.contains(id)) continue;
      _pending[id] = DetectedPayment(
        id: id,
        message: message,
        receivedAt: _now.subtract(Duration(minutes: 10 * (i + 1))),
      );
    }
  }
}
