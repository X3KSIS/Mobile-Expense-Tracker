import '../../../domain/models/bill.dart';

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/account_link.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/detected_payment.dart';
import '../../../domain/models/money_message.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/transfer.dart';
import '../../../domain/models/wallet.dart';
import 'app_database.dart';

/// Converts database rows to domain models and back. Writes made here are
/// always marked dirty, so the sync sends them.

extension CategoryRowMapping on CategoryRow {
  TransactionCategory toDomain() => TransactionCategory(
    id: id,
    name: name,
    icon: icon,
    color: color,
    type: TransactionType.values.byName(type),
  );
}

extension CategoryToRow on TransactionCategory {
  CategoriesCompanion toCompanion({
    required DateTime modifiedAt,
    required int sortOrder,
    bool dirty = true,
  }) => CategoriesCompanion.insert(
    id: id,
    name: name,
    icon: icon,
    color: color,
    type: type.name,
    sortOrder: Value(sortOrder),
    modifiedAt: modifiedAt,
    dirty: Value(dirty),
  );
}

extension WalletRowMapping on WalletRow {
  Wallet toDomain() => Wallet(
    id: id,
    name: name,
    kind: WalletKind.values.byName(kind),
    openingBalance: openingBalance,
  );
}

extension WalletToRow on Wallet {
  WalletsCompanion toCompanion({
    required DateTime modifiedAt,
    required int sortOrder,
    bool dirty = true,
  }) => WalletsCompanion.insert(
    id: id,
    name: name,
    kind: kind.name,
    openingBalance: Value(openingBalance),
    sortOrder: Value(sortOrder),
    modifiedAt: modifiedAt,
    dirty: Value(dirty),
  );
}

extension TransferRowMapping on TransferRow {
  Transfer toDomain() => Transfer(
    id: id,
    fromWalletId: fromWalletId,
    toWalletId: toWalletId,
    amount: amount,
    date: date,
    note: note,
  );
}

extension TransferToRow on Transfer {
  TransfersCompanion toCompanion({required DateTime modifiedAt}) =>
      TransfersCompanion.insert(
        id: id,
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        date: date,
        note: Value(note),
        modifiedAt: modifiedAt,
        dirty: const Value(true),
      );
}

extension TransactionRowMapping on TransactionRow {
  Transaction toDomain() => Transaction(
    id: id,
    title: title,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    amount: amount,
    type: TransactionType.values.byName(type),
    date: date,
    note: note,
    walletId: walletId,
  );
}

extension TransactionToRow on Transaction {
  TransactionsCompanion toCompanion({required DateTime modifiedAt}) =>
      TransactionsCompanion.insert(
        id: id,
        title: title,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
        amount: amount,
        type: type.name,
        date: date,
        note: Value(note),
        walletId: walletId,
        modifiedAt: modifiedAt,
        dirty: const Value(true),
      );
}

extension BudgetRowMapping on BudgetRow {
  Budget toDomain() => Budget(
    id: id,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    limit: limitAmount,
  );
}

extension BudgetToRow on Budget {
  BudgetsCompanion toCompanion({
    required DateTime modifiedAt,
    required int sortOrder,
  }) => BudgetsCompanion.insert(
    id: id,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    limitAmount: limit,
    sortOrder: Value(sortOrder),
    modifiedAt: modifiedAt,
    dirty: const Value(true),
  );
}

extension DetectedPaymentRowMapping on DetectedPaymentRow {
  DetectedPayment toDomain() => DetectedPayment(
    id: id,
    message: MoneyMessage.fromJson(
      (jsonDecode(message) as Map).cast<String, Object?>(),
    ),
    receivedAt: receivedAt,
    sender: sender,
  );
}

extension DetectedPaymentToRow on DetectedPayment {
  DetectedPaymentsCompanion toCompanion({required DateTime modifiedAt}) =>
      DetectedPaymentsCompanion.insert(
        id: id,
        message: jsonEncode(message.toJson()),
        receivedAt: receivedAt,
        sender: Value(sender),
        modifiedAt: modifiedAt,
        dirty: const Value(true),
      );
}

extension AccountLinkRowMapping on AccountLinkRow {
  AccountLink toDomain() => AccountLink(
    walletId: id,
    providerName: providerName,
    accountRef: accountRef,
    lastSyncedAt: lastSyncedAt,
  );
}

extension AccountLinkToRow on AccountLink {
  AccountLinksCompanion toCompanion({required DateTime modifiedAt}) =>
      AccountLinksCompanion.insert(
        id: walletId,
        providerName: providerName,
        accountRef: accountRef,
        lastSyncedAt: Value(lastSyncedAt),
        modifiedAt: modifiedAt,
        dirty: const Value(true),
      );
}

extension BillRowMapping on BillRow {
  Bill toDomain() => Bill(
    id: id,
    name: name,
    amount: amount,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    walletId: walletId,
    cadence: BillCadence.values.asNameMap()[cadence] ?? BillCadence.monthly,
    nextDue: nextDue,
    anchorDay: anchorDay,
  );
}

extension BillToRow on Bill {
  BillsCompanion toCompanion({required DateTime modifiedAt}) =>
      BillsCompanion.insert(
        id: id,
        name: name,
        amount: amount,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
        walletId: walletId,
        cadence: cadence.name,
        nextDue: nextDue,
        anchorDay: anchorDay,
        modifiedAt: modifiedAt,
        dirty: const Value(true),
      );
}
