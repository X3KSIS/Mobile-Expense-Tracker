import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/domain/models/monthly_summary.dart';
import 'package:flutter_expensetracker/domain/models/transaction.dart';
import 'package:flutter_expensetracker/utils/result.dart';

/// A [TransactionRepository] whose calls fail while [shouldFail] is true.
class FailingTransactionRepository implements TransactionRepository {
  FailingTransactionRepository(this._delegate, {this.shouldFail = true});

  final TransactionRepository _delegate;

  /// Flip to false to let calls through to the delegate.
  bool shouldFail;

  static final Exception failure = Exception('Network unavailable');

  @override
  Future<Result<MonthlySummary>> getMonthlySummary() async =>
      shouldFail ? Result.error(failure) : _delegate.getMonthlySummary();

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({
    int limit = 5,
  }) async => shouldFail
      ? Result.error(failure)
      : _delegate.getRecentTransactions(limit: limit);
}
