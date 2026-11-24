import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';

/// Fake repositories with no simulated latency, so tests run instantly.
TransactionRepositoryLocalFake instantTransactionRepository({DateTime? now}) =>
    TransactionRepositoryLocalFake(now: now, delay: Duration.zero);

BudgetRepositoryLocalFake instantBudgetRepository() =>
    BudgetRepositoryLocalFake(delay: Duration.zero);
