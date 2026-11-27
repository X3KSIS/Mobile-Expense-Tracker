import 'package:flutter/material.dart';

import '../core/themes/dimens.dart';
import '../core/themes/theme.dart';
import '../core/ui/empty_state.dart';

/// Shown instead of the app when it was built without the Supabase
/// settings, so nobody can sign in to an account that isn't real.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Dimens.screenPadding),
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Not connected to the server',
                message:
                    'This build has no Supabase settings, so sign-in is '
                    'turned off. Check SUPABASE_URL and '
                    'SUPABASE_PUBLISHABLE_KEY in supabase.json.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
