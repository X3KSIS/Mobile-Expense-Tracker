import 'money_message.dart';

/// A payment read from a notification on the phone (an MTN MoMo, Airtel
/// Money, Zamtel or bank message), waiting for the user to add it as a
/// transaction or dismiss it. Nothing is saved without the user's say.
class DetectedPayment {
  const DetectedPayment({
    required this.id,
    required this.message,
    required this.receivedAt,
    this.sender,
  });

  /// The message's reference when it has one, so the same payment seen
  /// twice is only offered once.
  final String id;

  final MoneyMessage message;

  /// When the notification arrived.
  final DateTime receivedAt;

  /// The notification's title, usually the SMS sender (e.g. "MoMo").
  final String? sender;

  @override
  bool operator ==(Object other) => other is DetectedPayment && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DetectedPayment($id, ${message.amount})';
}
