import 'package:flutter/foundation.dart';

import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_draft.dart';
import '../../../utils/result.dart';

/// Source of truth for transactions and their monthly totals.
///
/// Extends [ChangeNotifier] and notifies after every add, edit or delete, so
/// ViewModels can reload.
abstract class TransactionRepository extends ChangeNotifier {
  /// All transactions, newest first.
  Future<Result<List<Transaction>>> getTransactions();

  /// The [limit] most recent transactions, newest first.
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 5});

  /// Income, expenses and net for the month containing [month], or the
  /// current month when null.
  Future<Result<MonthlySummary>> getMonthlySummary({DateTime? month});

  /// Saves a new transaction and returns it with its id.
  Future<Result<Transaction>> addTransaction(TransactionDraft draft);

  /// Replaces the transaction [id] with [draft], keeping its id.
  Future<Result<Transaction>> updateTransaction(
    String id,
    TransactionDraft draft,
  );

  Future<Result<void>> deleteTransaction(String id);

  /// Brings back a transaction deleted with [deleteTransaction] (Undo).
  Future<Result<void>> restoreTransaction(String id);
}
