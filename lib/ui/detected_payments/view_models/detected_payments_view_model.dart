import 'package:flutter/foundation.dart';

import '../../../data/repositories/detected_payment/detected_payment_repository.dart';
import '../../../domain/models/detected_payment.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// State for the "From your messages" screen: notification access, and the
/// payments read from notifications that wait to be added or dismissed.
class DetectedPaymentsViewModel extends ChangeNotifier {
  DetectedPaymentsViewModel({required this._repository}) {
    _repository.addListener(_onChanged);
    enable = Command0<void>(_enable);
    dismiss = Command1<void, String>(_repository.dismiss);
    markAdded = Command1<void, String>(_repository.markAdded);
  }

  final DetectedPaymentRepository _repository;

  /// Asks for notification access.
  late final Command0<void> enable;

  late final Command1<void, String> dismiss;

  /// Clears a payment once it has been saved as a transaction.
  late final Command1<void, String> markAdded;

  bool _disposed = false;

  bool get isSupported => _repository.isSupported;

  bool get isEnabled => _repository.isEnabled;

  List<DetectedPayment> get pending => _repository.pending;

  Future<Result<void>> _enable() async {
    final result = await _repository.enable();
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  void _onChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.removeListener(_onChanged);
    enable.dispose();
    dismiss.dispose();
    markAdded.dispose();
    super.dispose();
  }
}
