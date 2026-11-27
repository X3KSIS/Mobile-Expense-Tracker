import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/account_link/account_link_repository.dart';
import '../data/repositories/account_link/account_link_repository_api.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local_fake.dart';
import '../data/repositories/budget/budget_repository.dart';
import '../data/repositories/budget/budget_repository_local_fake.dart';
import '../data/repositories/category/category_repository.dart';
import '../data/repositories/detected_payment/detected_payment_repository.dart';
import '../data/repositories/detected_payment/detected_payment_repository_notifications.dart';
import '../data/repositories/category/category_repository_local_fake.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_local_fake.dart';
import '../data/repositories/transaction/transaction_repository.dart';
import '../data/repositories/transaction/transaction_repository_local_fake.dart';
import '../data/repositories/wallet/wallet_repository.dart';
import '../data/repositories/wallet/wallet_repository_local_fake.dart';

/// App-level providers. Repositories live here; ViewModels are created in
/// the route builders.
///
/// Swap the `*LocalFake` implementations for real ones once Firebase Auth,
/// Drift and the Django API are wired in.
List<SingleChildWidget> get providersLocal => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => AuthRepositoryLocalFake(),
  ),
  ChangeNotifierProvider<TransactionRepository>(
    create: (_) => TransactionRepositoryLocalFake(),
  ),
  ChangeNotifierProvider<BudgetRepository>(
    create: (_) => BudgetRepositoryLocalFake(),
  ),
  Provider<CategoryRepository>(create: (_) => CategoryRepositoryLocalFake()),
  ChangeNotifierProvider<SettingsRepository>(
    create: (_) => SettingsRepositoryLocalFake(),
  ),
  ChangeNotifierProvider<WalletRepository>(
    create: (_) => WalletRepositoryLocalFake(),
  ),
  // Real already: reads the phone's notifications (Android only).
  ChangeNotifierProvider<DetectedPaymentRepository>(
    create: (_) => DetectedPaymentRepositoryNotifications(),
  ),
  // Ready for institution APIs (MTN MoMo, Airtel Money, banks). Add a
  // ProviderApiService for each one once API access is granted.
  ChangeNotifierProvider<AccountLinkRepository>(
    create: (_) => AccountLinkRepositoryApi(),
  ),
];
