import 'package:flutter_expensetracker/data/repositories/account_link/account_link_repository.dart';
import 'package:flutter_expensetracker/data/repositories/account_link/account_link_repository_api.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository.dart';
import 'package:flutter_expensetracker/data/repositories/app_lock/app_lock_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository.dart';
import 'package:flutter_expensetracker/data/repositories/budget/budget_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository.dart';
import 'package:flutter_expensetracker/data/repositories/category/category_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository.dart';
import 'package:flutter_expensetracker/data/repositories/detected_payment/detected_payment_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/reminder/reminder_repository.dart';
import 'package:flutter_expensetracker/data/repositories/reminder/reminder_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository.dart';
import 'package:flutter_expensetracker/data/repositories/settings/settings_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository.dart';
import 'package:flutter_expensetracker/data/repositories/transaction/transaction_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/wallet/wallet_repository.dart';
import 'package:flutter_expensetracker/data/repositories/wallet/wallet_repository_local_fake.dart';
import 'package:flutter_expensetracker/data/repositories/sync/sync_repository.dart';

import 'fake_sync_repository.dart';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

export 'fake_sync_repository.dart';

/// Fake repositories with no simulated latency, so tests run instantly.
TransactionRepositoryLocalFake instantTransactionRepository({DateTime? now}) =>
    TransactionRepositoryLocalFake(now: now, delay: Duration.zero);

BudgetRepositoryLocalFake instantBudgetRepository() =>
    BudgetRepositoryLocalFake(delay: Duration.zero);

WalletRepositoryLocalFake instantWalletRepository({DateTime? now}) =>
    WalletRepositoryLocalFake(now: now, delay: Duration.zero);

CategoryRepositoryLocalFake instantCategoryRepository() =>
    CategoryRepositoryLocalFake(delay: Duration.zero);

/// Starts signed out unless [signedIn] is true. Any credentials sign in
/// to the demo account.
AuthRepositoryLocalFake instantAuthRepository({
  bool signedIn = false,
  DateTime? now,
}) =>
    AuthRepositoryLocalFake(delay: Duration.zero, signedIn: signedIn, now: now);

/// Payment messages the fake detected-payment repository offers once
/// notification access is turned on.
const List<String> sampleMessages = [
  'MoMo: You have paid ZMW 60.00 to CHICKEN INN LEVY. Fee ZMW 1.00. '
      'Txn ID: 700001.',
  'AirtelMoney. Money received. Amt: K300.00 From: 0971234567 '
      'MARY PHIRI. TID: MP700002.',
];

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
  ChangeNotifierProvider<AppLockRepository>(
    create: (_) => AppLockRepositoryLocalFake(),
  ),
  Provider<ReminderRepository>(
    create: (_) => ReminderRepositoryLocalFake(),
    dispose: (_, r) => r.dispose(),
  ),
  ChangeNotifierProvider<WalletRepository>(
    create: (_) => instantWalletRepository(),
  ),
  ChangeNotifierProvider<DetectedPaymentRepository>(
    create: (_) => DetectedPaymentRepositoryLocalFake(incoming: sampleMessages),
  ),
  ChangeNotifierProvider<CategoryRepository>(
    create: (_) => instantCategoryRepository(),
  ),
  ChangeNotifierProvider<AccountLinkRepository>(
    create: (_) => AccountLinkRepositoryApi(),
  ),
  ChangeNotifierProvider<SyncRepository>(create: (_) => FakeSyncRepository()),
];
