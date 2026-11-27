import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'data/repositories/auth/auth_repository.dart';
import 'data/repositories/detected_payment/detected_payment_repository.dart';
import 'data/repositories/settings/settings_repository.dart';
import 'data/repositories/sync/sync_repository.dart';
import 'data/services/supabase/supabase_config.dart';
import 'domain/models/theme_preference.dart';
import 'routing/router.dart';
import 'ui/core/themes/motion.dart';
import 'ui/core/themes/theme.dart';
import 'ui/setup/setup_required_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }
  final providers = await createProviders(config);
  runApp(MultiProvider(providers: providers, child: const ExpenseTrackApp()));
}

class ExpenseTrackApp extends StatefulWidget {
  const ExpenseTrackApp({super.key});

  @override
  State<ExpenseTrackApp> createState() => _ExpenseTrackAppState();
}

class _ExpenseTrackAppState extends State<ExpenseTrackApp>
    with WidgetsBindingObserver {
  late final GoRouter _router = router(context.read<AuthRepository>());
  late final AuthRepository _auth = context.read<AuthRepository>();
  late final SyncRepository _sync = context.read<SyncRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    // After the first frame: starting a sync announces its status, and
    // listeners must not be told about changes in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onAuthChanged();
      _refreshDetectedPayments();
    });
  }

  /// Syncs while someone is signed in.
  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      _sync.start();
    } else {
      _sync.stop();
    }
  }

  /// Payment notifications only arrive while the app runs, so on start
  /// and every return to the foreground pick up those still in the tray
  /// (and notice if notification access was just turned on or off).
  /// Coming back is also a good moment to fetch other devices' changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshDetectedPayments();
    if (_auth.isAuthenticated) _sync.sync();
  }

  void _refreshDetectedPayments() =>
      context.read<DetectedPaymentRepository>().refresh();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_onAuthChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference = context.select<SettingsRepository, ThemePreference>(
      (settings) => settings.themePreference,
    );
    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (preference) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      // Every colour blends from one palette to the other.
      themeAnimationDuration: AppMotion.theme,
      themeAnimationCurve: AppMotion.move,
      routerConfig: _router,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child!,
      ),
    );
  }
}
