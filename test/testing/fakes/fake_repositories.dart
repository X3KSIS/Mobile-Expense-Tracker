import 'package:flutter_expensetracker/data/repositories/auth/auth_repository.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Fake repositories with no simulated latency, so tests run instantly.
TransactionRepositoryLocalFake instantTransactionRepository({DateTime? now}) =>
    TransactionRepositoryLocalFake(now: now, delay: Duration.zero);

BudgetRepositoryLocalFake instantBudgetRepository() =>
    BudgetRepositoryLocalFake(delay: Duration.zero);

CategoryRepositoryLocalFake instantCategoryRepository() =>
    CategoryRepositoryLocalFake(delay: Duration.zero);

/// Starts signed out unless [signedIn] is true. Any credentials sign in
/// to the demo account.
AuthRepositoryLocalFake instantAuthRepository({
  bool signedIn = false,
  DateTime? now,
}) =>
    AuthRepositoryLocalFake(delay: Duration.zero, signedIn: signedIn, now: now);

/// App-level providers backed by instant fakes, for whole-app tests.
List<SingleChildWidget> instantAppProviders({bool signedIn = false}) => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => instantAuthRepository(signedIn: signedIn),
  ),
  ChangeNotifierProvider<TransactionRepository>(
    create: (_) => instantTransactionRepository(),
  ),
  ChangeNotifierProvider<BudgetRepository>(
    create: (_) => instantBudgetRepository(),
  ),
  ChangeNotifierProvider<SettingsRepository>(
    create: (_) => SettingsRepositoryLocalFake(),
  ),
  Provider<CategoryRepository>(create: (_) => instantCategoryRepository()),
];
