import 'wallet.dart';

/// What a mobile money or bank message describes.
enum MoneyMessageKind {
  /// Money came in: received, credited, deposited.
  received,

  /// Money went out: paid, sent, bought, debited.
  spent,

  /// Cash taken out at an agent or ATM. Better recorded as a transfer
  /// from the account to the Cash wallet.
  withdrawal,
}

/// The details read from a mobile money or bank SMS.
class MoneyMessage {
  const MoneyMessage({
    required this.kind,
    required this.amount,
    this.provider,
    this.providerKind,
    this.counterparty,
    this.fee,
    this.balance,
    this.reference,
    this.date,
    this.categoryHint,
  });

  final MoneyMessageKind kind;

  /// Always positive.
  final double amount;

  /// e.g. "MTN MoMo", "Airtel Money", "Zanaco".
  final String? provider;

  /// Whether [provider] is a mobile money service or a bank.
  final WalletKind? providerKind;

  /// Who paid or was paid, e.g. "Shoprite Manda Hill" or "John Banda".
  final String? counterparty;

  /// Charge for the transaction, when the message gives one above zero.
  final double? fee;

  /// Balance after the transaction.
  final double? balance;

  /// Transaction ID or reference.
  final String? reference;

  /// When it happened, if the message says.
  final DateTime? date;

  /// A category name guessed from the text, e.g. "Utilities" for ZESCO.
  final String? categoryHint;

  bool get isIncome => kind == MoneyMessageKind.received;
}
