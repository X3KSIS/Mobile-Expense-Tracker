import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'data/repositories/auth/auth_repository.dart';
import 'data/repositories/settings/settings_repository.dart';
import 'domain/models/theme_preference.dart';
import 'routing/router.dart';
import 'ui/core/themes/motion.dart';
import 'ui/core/themes/theme.dart';

void main() {
  runApp(
    MultiProvider(providers: providersLocal, child: const ExpenseTrackApp()),
  );
}

class ExpenseTrackApp extends StatefulWidget {
  const ExpenseTrackApp({super.key});

  @override
  State<ExpenseTrackApp> createState() => _ExpenseTrackAppState();
}

class _ExpenseTrackAppState extends State<ExpenseTrackApp> {
  late final GoRouter _router = router(context.read<AuthRepository>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference = context.select<SettingsRepository, ThemePreference>(
      (settings) => settings.themePreference,
    );
    return MaterialApp.router(
      title: 'ExpenseTrack',
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
