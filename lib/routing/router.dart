import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../domain/models/transaction.dart';
import '../ui/activity/view_models/activity_view_model.dart';
import '../ui/activity/widgets/activity_screen.dart';
import '../ui/add_transaction/view_models/add_transaction_view_model.dart';
import '../ui/add_transaction/widgets/add_transaction_screen.dart';
import '../ui/auth/view_models/login_view_model.dart';
import '../ui/auth/view_models/sign_up_view_model.dart';
import '../ui/auth/widgets/login_screen.dart';
import '../ui/auth/widgets/sign_up_screen.dart';
import '../ui/budgets/view_models/budgets_view_model.dart';
import '../ui/budgets/widgets/budgets_screen.dart';
import '../ui/core/themes/motion.dart';
import '../ui/core/ui/animated_branch_container.dart';
import '../ui/core/ui/app_shell.dart';
import '../ui/home/view_models/home_view_model.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/profile/view_models/edit_profile_view_model.dart';
import '../ui/profile/view_models/profile_view_model.dart';
import '../ui/profile/widgets/edit_profile_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/reports/view_models/reports_view_model.dart';
import '../ui/reports/widgets/reports_screen.dart';
import '../ui/search/view_models/search_view_model.dart';
import '../ui/search/widgets/search_screen.dart';
import '../ui/splash/view_models/splash_view_model.dart';
import '../ui/splash/widgets/splash_screen.dart';
import '../ui/wallets/view_models/wallets_view_model.dart';
import '../ui/wallets/widgets/wallets_screen.dart';
import 'routes.dart';

/// Builds the app router. ViewModels are created here, in the route
/// builders, and disposed with their route by [ChangeNotifierProvider].
///
/// The router listens to [authRepository]: signing in sends the user to
/// Home and signing out sends them to the sign-in screen.
GoRouter router(AuthRepository authRepository) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: _AuthStatusListenable(authRepository),
    redirect: (context, state) => _redirect(authRepository, state),
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider(
            create: (context) =>
                SplashViewModel(authRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  SplashScreen(viewModel: context.read<SplashViewModel>()),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider(
            create: (context) => LoginViewModel(authRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  LoginScreen(viewModel: context.read<LoginViewModel>()),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.signUp,
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider(
            create: (context) =>
                SignUpViewModel(authRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  SignUpScreen(viewModel: context.read<SignUpViewModel>()),
            ),
          ),
        ),
      ),
      _shell(),
      GoRoute(
        path: Routes.add,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return ChangeNotifierProvider(
            create: (context) => AddTransactionViewModel(
              transactionRepository: context.read(),
              categoryRepository: context.read(),
              walletRepository: context.read(),
              initialType: query[Routes.typeParam] == 'income'
                  ? TransactionType.income
                  : TransactionType.expense,
              initialCategoryId: query[Routes.categoryParam],
            ),
            child: Builder(
              builder: (context) => AddTransactionScreen(
                viewModel: context.read<AddTransactionViewModel>(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: rootNavigatorKey,
        // A plain fade, so the search box's hero flight is the one movement.
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangeNotifierProvider(
            create: (context) =>
                SearchViewModel(transactionRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  SearchScreen(viewModel: context.read<SearchViewModel>()),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.wallets,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => WalletsViewModel(
            walletRepository: context.read(),
            transactionRepository: context.read(),
            categoryRepository: context.read(),
          ),
          child: Builder(
            builder: (context) =>
                WalletsScreen(viewModel: context.read<WalletsViewModel>()),
          ),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => ProfileViewModel(
            authRepository: context.read(),
            settingsRepository: context.read(),
          ),
          child: Builder(
            builder: (context) =>
                ProfileScreen(viewModel: context.read<ProfileViewModel>()),
          ),
        ),
        routes: [
          GoRoute(
            path: Routes.editProfileSegment,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) =>
                  EditProfileViewModel(authRepository: context.read()),
              child: Builder(
                builder: (context) => EditProfileScreen(
                  viewModel: context.read<EditProfileViewModel>(),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Fades a full-screen page in. Used where go_router replaces the whole
/// stack (splash, sign-in, sign-up, the main shell) so the hand-off is a
/// soft cross-fade rather than a hard cut.
Page<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: AppMotion.long,
      reverseTransitionDuration: AppMotion.medium,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
            child: child,
          ),
    );

/// Keeps signed-out users on the auth screens and signed-in users off them.
/// The splash screen decides for itself once it has finished.
String? _redirect(AuthRepository authRepository, GoRouterState state) {
  final location = state.matchedLocation;
  if (location == Routes.splash) return null;
  final onAuthScreen = Routes.signedOut.contains(location);
  if (!authRepository.isAuthenticated) {
    return onAuthScreen ? null : Routes.login;
  }
  return onAuthScreen ? Routes.home : null;
}

/// Notifies only when the user signs in or out.
///
/// The repository also notifies on profile edits. Refreshing the router for
/// those races with popping the edit screen and leaves a stale route behind,
/// so the router listens to this filtered signal instead.
class _AuthStatusListenable extends ChangeNotifier {
  _AuthStatusListenable(this._authRepository)
    : _signedIn = _authRepository.isAuthenticated {
    _authRepository.addListener(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  bool _signedIn;

  void _onAuthChanged() {
    final signedIn = _authRepository.isAuthenticated;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    notifyListeners();
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthChanged);
    super.dispose();
  }
}

StatefulShellRoute _shell() => StatefulShellRoute(
  pageBuilder: (context, state, navigationShell) =>
      _fadePage(state, AppShell(navigationShell: navigationShell)),
  navigatorContainerBuilder: (context, navigationShell, children) =>
      AnimatedBranchContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => HomeViewModel(
              transactionRepository: context.read(),
              budgetRepository: context.read(),
              authRepository: context.read(),
              settingsRepository: context.read(),
              walletRepository: context.read(),
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
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) =>
                ActivityViewModel(transactionRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  ActivityScreen(viewModel: context.read<ActivityViewModel>()),
            ),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: Routes.budgets,
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => BudgetsViewModel(
              budgetRepository: context.read(),
              transactionRepository: context.read(),
              categoryRepository: context.read(),
              settingsRepository: context.read(),
            ),
            child: Builder(
              builder: (context) =>
                  BudgetsScreen(viewModel: context.read<BudgetsViewModel>()),
            ),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: Routes.reports,
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) =>
                ReportsViewModel(transactionRepository: context.read()),
            child: Builder(
              builder: (context) =>
                  ReportsScreen(viewModel: context.read<ReportsViewModel>()),
            ),
          ),
        ),
      ],
    ),
  ],
);
