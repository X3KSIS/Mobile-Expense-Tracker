import 'package:flutter/foundation.dart';

import '../../../domain/models/transfer.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/result.dart';

/// Source of truth for wallets (cash, mobile money, bank) and the
/// transfers between them.
///
/// Extends [ChangeNotifier] and notifies after every change. Balances are
/// worked out with `WalletBalance.compute`.
abstract class WalletRepository extends ChangeNotifier {
  /// All wallets in the user's order.
  Future<Result<List<Wallet>>> getWallets();

  /// Adds [wallet] when its id is empty, otherwise replaces the wallet
  /// with the same id.
  Future<Result<Wallet>> saveWallet(Wallet wallet);

  /// All transfers, newest first.
  Future<Result<List<Transfer>>> getTransfers();

  /// Saves a transfer; an empty id gets a new one.
  Future<Result<Transfer>> addTransfer(Transfer transfer);

  Future<Result<void>> deleteTransfer(String id);
}
