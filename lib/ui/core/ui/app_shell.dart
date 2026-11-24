import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../themes/dimens.dart';
import 'floating_nav_bar.dart';

/// Hosts the four main tabs and the floating bottom bar.
///
/// Screens inside the shell draw behind the bar, so scrollable content must
/// add [Dimens.navBarClearance] as bottom padding.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavDestination> destinations = [
    NavDestination(icon: Icons.home_outlined, label: 'Home'),
    NavDestination(icon: Icons.swap_horiz_rounded, label: 'Activity'),
    NavDestination(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Budgets',
    ),
    NavDestination(icon: Icons.insert_chart_outlined_rounded, label: 'Reports'),
  ];

  void _onDestinationSelected(int index) {
    // Tapping the active tab again returns it to its first page.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: Dimens.navBarMargin,
            right: Dimens.navBarMargin,
            bottom: Dimens.navBarMargin + bottomInset,
            child: FloatingNavBar(
              destinations: destinations,
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              onAddPressed: () => context.push(Routes.add),
            ),
          ),
        ],
      ),
    );
  }
}
