import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local_fake.dart';
import '../data/repositories/budget/budget_repository.dart';
import '../data/repositories/budget/budget_repository_local_fake.dart';
import '../data/repositories/transaction/transaction_repository.dart';
import '../data/repositories/transaction/transaction_repository_local_fake.dart';

/// App-level providers. Repositories live here; ViewModels are created in
/// the route builders.
///
/// Swap the `*LocalFake` implementations for real ones once Firebase Auth,
/// Drift and the Django API are wired in.
List<SingleChildWidget> get providersLocal => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => AuthRepositoryLocalFake(),
  ),
  Provider<TransactionRepository>(
    create: (_) => TransactionRepositoryLocalFake(),
  ),
  Provider<BudgetRepository>(create: (_) => BudgetRepositoryLocalFake()),
];
