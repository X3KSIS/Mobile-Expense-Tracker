import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/domain/models/monthly_summary.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/domain/models/transaction_draft.dart';
import 'package:flutter_expensetracker/utils/result.dart';

/// A [TransactionRepository] whose calls fail while [shouldFail] is true.
class FailingTransactionRepository extends TransactionRepository {
  FailingTransactionRepository(this._delegate, {this.shouldFail = true});

  final TransactionRepository _delegate;

  /// Flip to false to let calls through to the delegate.
  bool shouldFail;

  static final Exception failure = Exception('Network unavailable');

  @override
  Future<Result<List<Transaction>>> getTransactions() async =>
      shouldFail ? Result.error(failure) : _delegate.getTransactions();

  @override
  Future<Result<MonthlySummary>> getMonthlySummary({DateTime? month}) async =>
      shouldFail
      ? Result.error(failure)
      : _delegate.getMonthlySummary(month: month);

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({
    int limit = 5,
  }) async => shouldFail
      ? Result.error(failure)
      : _delegate.getRecentTransactions(limit: limit);

  @override
  Future<Result<Transaction>> addTransaction(TransactionDraft draft) async =>
      shouldFail ? Result.error(failure) : _delegate.addTransaction(draft);

  @override
  Future<Result<Transaction>> updateTransaction(
    String id,
    TransactionDraft draft,
  ) async => shouldFail
      ? Result.error(failure)
      : _delegate.updateTransaction(id, draft);

  @override
  Future<Result<void>> restoreTransaction(String id) async =>
      shouldFail ? Result.error(failure) : _delegate.restoreTransaction(id);

  @override
  Future<Result<void>> deleteTransaction(String id) async =>
      shouldFail ? Result.error(failure) : _delegate.deleteTransaction(id);
}
