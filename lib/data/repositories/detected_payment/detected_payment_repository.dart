import 'package:flutter/foundation.dart';

import '../../../domain/models/detected_payment.dart';
import '../../../utils/result.dart';

/// Source of truth for payments read from the phone's notifications.
///
/// Extends [ChangeNotifier] and notifies when payments arrive, are added
/// or dismissed, or when notification access changes.
abstract class DetectedPaymentRepository extends ChangeNotifier {
  /// Whether this device can read notifications at all (Android only).
  bool get isSupported;

  /// Whether the user has allowed notification access.
  bool get isEnabled;

  /// Payments waiting to be added or dismissed, newest first.
  List<DetectedPayment> get pending;

  /// Re-checks access, starts listening when allowed, and picks up payment
  /// messages still in the notification tray. Call on start and whenever
  /// the app comes back to the foreground.
  Future<Result<void>> refresh();

  /// Asks for notification access (opens the system settings page) and
  /// starts listening if granted. Resolves to whether access is on.
  Future<Result<bool>> enable();

  /// Removes the payment from [pending] because it was added.
  Future<Result<void>> markAdded(String id);

  /// Removes the payment from [pending] without adding it.
  Future<Result<void>> dismiss(String id);
}
