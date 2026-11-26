/// Money moved between two of the user's wallets, e.g. withdrawing mobile
/// money to cash or sending from the bank to MoMo.
///
/// A transfer is neither income nor expense. Any charge for it is recorded
/// as a separate "Fees & charges" expense from [fromWalletId].
class Transfer {
  const Transfer({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String fromWalletId;
  final String toWalletId;

  /// Always positive.
  final double amount;
  final DateTime date;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.id == id &&
      other.fromWalletId == fromWalletId &&
      other.toWalletId == toWalletId &&
      other.amount == amount &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, fromWalletId, toWalletId, amount, date, note);

  @override
  String toString() =>
      'Transfer($id, $fromWalletId -> $toWalletId, $amount, $date)';
}
