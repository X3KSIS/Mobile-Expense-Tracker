import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/theme_preference.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/expandable_section.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/payday_picker.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../../core/ui/slow_refresh.dart';
import '../view_models/home_view_model.dart';
import 'balance_card.dart';
import 'budget_alert_card.dart';
import 'detected_payments_banner.dart';
import 'habit_card.dart';
import 'home_error_view.dart';
import 'home_header.dart';
import 'quick_actions.dart';
import 'recent_activity.dart';
import 'safe_to_spend_card.dart';
import 'wallet_strip.dart';

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
            final Widget content;
            if (viewModel.isLoading) {
              content = const HomeSkeleton(key: ValueKey('loading'));
            } else if (!viewModel.hasData) {
              content = HomeErrorView(
                key: const ValueKey('error'),
                onRetry: viewModel.load.execute,
              );
            } else {
              content = SlowRefresh(
                key: const ValueKey('content'),
                onRefresh: viewModel.load.execute,
                child: _HomeContent(
                  viewModel: viewModel,
                  onNotificationsPressed: () =>
                      _showComingSoon('Notifications'),
                ),
              );
            }
            return FadeSwitcher(animateSize: false, child: content);
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
          isDarkMode: switch (viewModel.themePreference) {
            ThemePreference.dark => true,
            ThemePreference.light => false,
            ThemePreference.system =>
              MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          },
          onDarkModeChanged: viewModel.setDarkMode,
        ),
        ExpandableSection(
          expanded: viewModel.detectedPaymentCount > 0,
          child: Padding(
            padding: const EdgeInsets.only(top: Dimens.gapL),
            child: DetectedPaymentsBanner(
              count: viewModel.detectedPaymentCount,
              onReview: () => context.push(Routes.detectedPayments),
            ),
          ),
        ),
        const SizedBox(height: Dimens.sectionGap),
        BalanceCard(
          summary: summary,
          hideAmounts: viewModel.hideAmounts,
          onToggleHideAmounts: viewModel.toggleHideAmounts,
        ),
        if (viewModel.topInsight case final insight?) ...[
          const SizedBox(height: Dimens.gapL),
          HabitCard(
            insight: insight,
            month: summary.month,
            onSeeAll: () => context.go(Routes.reports),
          ),
        ],
        if (viewModel.forecast case final forecast?) ...[
          const SizedBox(height: Dimens.gapL),
          SafeToSpendCard(
            forecast: forecast,
            payday: viewModel.payday,
            daysLeft: viewModel.daysToPayday,
            hideAmounts: viewModel.hideAmounts,
            onChangePayday: () async {
              final day = await showPaydayPicker(
                context,
                current: viewModel.payday,
              );
              if (day != null) viewModel.setPayday(day);
            },
          ),
        ],
        FadeSwitcher(
          child: alert == null
              ? const SizedBox(width: double.infinity, key: ValueKey('none'))
              : Padding(
                  key: const ValueKey('alert'),
                  padding: const EdgeInsets.only(top: Dimens.gapL),
                  child: BudgetAlertCard(
                    alert: alert,
                    onViewBudget: () => context.go(Routes.budgets),
                  ),
                ),
        ),
        if (viewModel.wallets.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          WalletStrip(
            wallets: viewModel.wallets,
            hideAmounts: viewModel.hideAmounts,
            onOpen: () => context.push(Routes.wallets),
          ),
        ],
        const SizedBox(height: Dimens.sectionGap),
        QuickActions(
          onSelected: (action) => context.push(_addRouteFor(action)),
        ),
        const SizedBox(height: Dimens.sectionGap),
        RecentActivity(
          transactions: viewModel.recentTransactions,
          onSeeAll: () => context.go(Routes.activity),
          onTransactionTap: (transaction) => showTransactionDetails(
            context,
            transaction: transaction,
            onDelete: () => viewModel.delete.execute(transaction.id),
          ),
        ),
      ],
    );
  }
}

/// Where each quick action leads. Receipts and grocery lists are later
/// features, so for now they open an expense (grocery preselects the
/// Groceries category).
String _addRouteFor(QuickAction action) => switch (action) {
  QuickAction.expense || QuickAction.receipt => Routes.addWith(type: 'expense'),
  QuickAction.income => Routes.addWith(type: 'income'),
  QuickAction.grocery => Routes.addWith(
    type: 'expense',
    categoryId: 'c-groceries',
  ),
};
