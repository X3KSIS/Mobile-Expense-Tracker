import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/account_link/account_link_repository.dart';
import '../data/repositories/account_link/account_link_repository_api.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local_fake.dart';
import '../data/repositories/auth/auth_repository_supabase.dart';
import '../data/repositories/budget/budget_repository.dart';
import '../data/repositories/budget/budget_repository_drift.dart';
import '../data/repositories/category/category_repository.dart';
import '../data/repositories/category/category_repository_drift.dart';
import '../data/repositories/detected_payment/detected_payment_repository.dart';
import '../data/repositories/detected_payment/detected_payment_repository_notifications.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_drift.dart';
import '../data/repositories/sync/sync_repository.dart';
import '../data/repositories/sync/sync_repository_drift.dart';
import '../data/repositories/transaction/transaction_repository.dart';
import '../data/repositories/transaction/transaction_repository_drift.dart';
import '../data/repositories/wallet/wallet_repository.dart';
import '../data/repositories/wallet/wallet_repository_drift.dart';
import '../data/services/database/app_database.dart';
import '../data/services/supabase/supabase_config.dart';
import '../data/services/sync/remote_store.dart';
import '../data/services/sync/supabase_remote_store.dart';

/// App-level providers. Repositories live here; ViewModels are created in
/// the route builders.
///
/// Everything is saved in the on-device database first (so the app works
/// offline) and synced to Supabase. Built without Supabase settings (see
/// [SupabaseConfig]), the app keeps data on this device only and signs in
/// with a demo account.
Future<List<SingleChildWidget>> createProviders(SupabaseConfig config) async {
  final db = AppDatabase();

  SupabaseClient? client;
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    client = Supabase.instance.client;
  }

  final syncRepository = SyncRepositoryDrift(
    db,
    client == null ? const NoRemoteStore() : SupabaseRemoteStore(client),
  );

  final AuthRepository auth;
  if (client == null) {
    auth = AuthRepositoryLocalFake(delay: const Duration(milliseconds: 300));
  } else {
    final supabaseAuth = AuthRepositorySupabase(
      client.auth,
      db,
      beforeSignOut: () => syncRepository.sync(),
    );
    await supabaseAuth.load();
    auth = supabaseAuth;
  }

  final settings = SettingsRepositoryDrift(db);
  await settings.load();

  return [
    Provider<AppDatabase>.value(value: db),
    ChangeNotifierProvider<AuthRepository>.value(value: auth),
    ChangeNotifierProvider<SyncRepository>.value(value: syncRepository),
    ChangeNotifierProvider<SettingsRepository>.value(value: settings),
    ChangeNotifierProvider<TransactionRepository>(
      create: (_) => TransactionRepositoryDrift(db),
    ),
    ChangeNotifierProvider<BudgetRepository>(
      create: (_) => BudgetRepositoryDrift(db),
    ),
    Provider<CategoryRepository>(create: (_) => CategoryRepositoryDrift(db)),
    ChangeNotifierProvider<WalletRepository>(
      create: (_) => WalletRepositoryDrift(db),
    ),
    // Reads the phone's notifications (Android only).
    ChangeNotifierProvider<DetectedPaymentRepository>(
      create: (_) => DetectedPaymentRepositoryNotifications(db),
    ),
    // Ready for institution APIs (MTN MoMo, Airtel Money, banks). Add a
    // ProviderApiService for each one once API access is granted.
    ChangeNotifierProvider<AccountLinkRepository>(
      create: (_) => AccountLinkRepositoryApi(database: db),
    ),
  ];
}
