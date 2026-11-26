import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transfer.dart';
import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/domain/models/wallet_balances.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../testing/fakes/fake_repositories.dart';

void main() {
  final day = DateTime(2026, 11, 20);
  const cash = Wallet(
    id: 'c',
    name: 'Cash',
    kind: WalletKind.cash,
    openingBalance: 100,
  );
  const momo = Wallet(id: 'm', name: 'MoMo', kind: WalletKind.mobileMoney);

  Transaction tx(String wallet, double amount, TransactionType type) =>
      Transaction(
        id: '$wallet$amount',
        title: 'x',
        categoryName: 'x',
        categoryIcon: 'other',
        categoryColor: 0,
        amount: amount,
        type: type,
        date: day,
        walletId: wallet,
      );

  test('adds income, subtracts expenses and moves transfers', () {
    final balances = WalletBalance.compute(
      [cash, momo],
      [
        tx('c', 30, TransactionType.expense),
        tx('m', 200, TransactionType.income),
        tx('unknown', 999, TransactionType.income),
      ],
      [
        Transfer(
          id: 't',
          fromWalletId: 'm',
          toWalletId: 'c',
          amount: 50,
          date: day,
        ),
      ],
    );

    expect(balances.map((b) => b.balance), [120, 150]);
    expect(WalletBalance.total(balances), 270);
  });

  test('the fake wallets all end up positive', () async {
    final now = DateTime(2026, 11, 25, 15);
    final wallets = instantWalletRepository(now: now);
    final transactions = instantTransactionRepository(now: now);
    final balances = WalletBalance.compute(
      (await wallets.getWallets() as Ok<List<Wallet>>).value,
      (await transactions.getTransactions() as Ok<List<Transaction>>).value,
      (await wallets.getTransfers() as Ok<List<Transfer>>).value,
    );

    for (final b in balances) {
      expect(b.balance, greaterThan(0), reason: b.wallet.name);
    }
  });

  test('a transfer needs two different wallets', () async {
    final wallets = instantWalletRepository();
    final result = await wallets.addTransfer(
      Transfer(
        id: '',
        fromWalletId: 'w-cash',
        toWalletId: 'w-cash',
        amount: 1,
        date: day,
      ),
    );
    expect(result, isA<Error<Transfer>>());
  });
}
