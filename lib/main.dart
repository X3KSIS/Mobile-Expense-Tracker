import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'routing/router.dart';
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
  late final GoRouter _router = router();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: 'ExpenseTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
