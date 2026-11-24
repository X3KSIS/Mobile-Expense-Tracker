import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/core/ui/app_shell.dart';
import '../ui/core/ui/placeholder_screen.dart';
import '../ui/home/view_models/home_view_model.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/splash/view_models/splash_view_model.dart';
import '../ui/splash/widgets/splash_screen.dart';
import 'routes.dart';

/// Builds the app router. ViewModels are created here, in the route
/// builders, and disposed with their route by [ChangeNotifierProvider].
GoRouter router() {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => SplashViewModel(),
          child: Builder(
            builder: (context) =>
                SplashScreen(viewModel: context.read<SplashViewModel>()),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => ChangeNotifierProvider(
                  create: (context) => HomeViewModel(
                    transactionRepository: context.read(),
                    budgetRepository: context.read(),
                  ),
                  child: Builder(
                    builder: (context) =>
                        HomeScreen(viewModel: context.read<HomeViewModel>()),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Activity',
                  icon: Icons.swap_horiz_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.budgets,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Budgets',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Reports',
                  icon: Icons.insert_chart_outlined_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.add,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Add transaction',
          icon: Icons.add_rounded,
          showBackButton: true,
        ),
      ),
    ],
  );
}
