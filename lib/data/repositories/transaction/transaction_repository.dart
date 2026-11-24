import '../../../domain/models/monthly_summary.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/result.dart';

/// Source of truth for transactions and their monthly totals.
abstract class TransactionRepository {
  /// The [limit] most recent transactions, newest first.
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 5});

  /// Income, expenses and net for the current month.
  Future<Result<MonthlySummary>> getMonthlySummary();
}
