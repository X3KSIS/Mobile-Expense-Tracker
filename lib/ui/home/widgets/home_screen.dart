import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../view_models/home_view_model.dart';
import 'balance_card.dart';
import 'budget_alert_card.dart';
import 'home_error_view.dart';
import 'home_header.dart';
import 'quick_actions.dart';
import 'recent_activity.dart';

/// Dashboard: header, balance, budget alert, quick actions and recent
/// activity. Pull down to refresh.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load.addListener(_onLoadChanged);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.load.removeListener(_onLoadChanged);
      widget.viewModel.load.addListener(_onLoadChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.load.removeListener(_onLoadChanged);
    super.dispose();
  }

  /// A failed refresh keeps the old data on screen and shows a snackbar.
  void _onLoadChanged() {
    final viewModel = widget.viewModel;
    if (!viewModel.hasError || !viewModel.hasData) return;
    viewModel.load.clearResult();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't refresh. Showing saved data.")),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!viewModel.hasData) {
              return HomeErrorView(onRetry: viewModel.load.execute);
            }
            return RefreshIndicator(
              onRefresh: viewModel.load.execute,
              child: _HomeContent(
                viewModel: viewModel,
                onNotificationsPressed: () => _showComingSoon('Notifications'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.viewModel,
    required this.onNotificationsPressed,
  });

  final HomeViewModel viewModel;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.summary!;
    final alert = viewModel.budgetAlert;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Dimens.screenPadding,
        Dimens.gapL,
        Dimens.screenPadding,
        Dimens.navBarClearance(context),
      ),
      children: [
        HomeHeader(
          userName: viewModel.userName,
          initials: viewModel.userInitials,
          onProfilePressed: () => context.push(Routes.profile),
          onNotificationsPressed: onNotificationsPressed,
        ),
        const SizedBox(height: Dimens.sectionGap),
        BalanceCard(
          summary: summary,
          hideAmounts: viewModel.hideAmounts,
          onToggleHideAmounts: viewModel.toggleHideAmounts,
        ),
        if (alert != null) ...[
          const SizedBox(height: Dimens.gapL),
          BudgetAlertCard(
            alert: alert,
            onViewBudget: () => context.go(Routes.budgets),
          ),
        ],
        const SizedBox(height: Dimens.sectionGap),
        QuickActions(onSelected: (_) => context.push(Routes.add)),
        const SizedBox(height: Dimens.sectionGap),
        RecentActivity(
          transactions: viewModel.recentTransactions,
          onSeeAll: () => context.go(Routes.activity),
        ),
      ],
    );
  }
}
