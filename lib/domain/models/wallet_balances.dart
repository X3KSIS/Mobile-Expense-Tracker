import 'transaction.dart';
import 'transfer.dart';
import 'wallet.dart';

/// A wallet with what it holds now.
class WalletBalance {
  const WalletBalance({required this.wallet, required this.balance});

  final Wallet wallet;
  final double balance;

  /// Balance of each wallet: opening balance, plus income, minus expenses,
  /// plus transfers in, minus transfers out. Transactions and transfers
  /// for unknown wallets are ignored. Keeps the order of [wallets].
  static List<WalletBalance> compute(
    List<Wallet> wallets,
    List<Transaction> transactions,
    List<Transfer> transfers,
  ) {
    final totals = {for (final w in wallets) w.id: w.openingBalance};
    void add(String walletId, double amount) {
      if (totals.containsKey(walletId)) {
        totals[walletId] = totals[walletId]! + amount;
      }
    }

    for (final t in transactions) {
      add(t.walletId, t.signedAmount);
    }
    for (final t in transfers) {
      add(t.fromWalletId, -t.amount);
      add(t.toWalletId, t.amount);
    }
    return [
      for (final w in wallets) WalletBalance(wallet: w, balance: totals[w.id]!),
    ];
  }

  /// Sum of all [balances].
  static double total(List<WalletBalance> balances) =>
      balances.fold(0, (sum, b) => sum + b.balance);

  @override
  bool operator ==(Object other) =>
      other is WalletBalance &&
      other.wallet == wallet &&
      other.balance == balance;

  @override
  int get hashCode => Object.hash(wallet, balance);
}
