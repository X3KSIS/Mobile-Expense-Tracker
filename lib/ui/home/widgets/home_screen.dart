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
import 'detected_payments_banner.dart';
import 'habit_card.dart';
import 'home_error_view.dart';
import 'home_header.dart';
import 'recent_activity.dart';
import 'spending_hero_card.dart';
import 'wallet_strip.dart';
import 'where_it_went.dart';

/// Dashboard, led by spending: what was spent this pay cycle and how it
/// compares, where it went, a habit tip, recent activity, then wallets.
/// Pull down to refresh.
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
                child: _HomeContent(viewModel: viewModel),
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
  const _HomeContent({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final spending = viewModel.spending;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Dimens.screenPadding,
        Dimens.gapL,
        Dimens.screenPadding,
        Dimens.navBarClearance(context),
      ),
      children: [
        _header(context),
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
        SpendingHeroCard(
          spending: spending,
          forecast: viewModel.forecast,
          daysToPayday: viewModel.daysToPayday,
          hideAmounts: viewModel.hideAmounts,
          onToggleHideAmounts: viewModel.toggleHideAmounts,
          onChangePayday: () => _changePayday(context),
        ),
        if (spending.categories.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          WhereItWent(
            categories: spending.categories,
            total: spending.spent,
            hideAmounts: viewModel.hideAmounts,
            onSeeAll: () => context.go(Routes.reports),
            onCategoryTap: (category) => context.push(
              Routes.categoryTrendFor(category.name, month: viewModel.now),
            ),
          ),
        ],
        if (viewModel.showHabits)
          if (viewModel.topInsight case final insight?) ...[
            const SizedBox(height: Dimens.sectionGap),
            HabitCard(
              insight: insight,
              month: viewModel.now,
              onSeeAll: () => context.go(Routes.reports),
            ),
          ],
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
        if (viewModel.wallets.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          WalletStrip(
            wallets: viewModel.wallets,
            hideAmounts: viewModel.hideAmounts,
            onOpen: () => context.push(Routes.wallets),
          ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context) => HomeHeader(
    userName: viewModel.userName,
    greeting: viewModel.greeting,
    displayName: viewModel.displayName,
    initials: viewModel.userInitials,
    photo: viewModel.userPhoto,
    onProfilePressed: () => context.push(Routes.profile),
    onNotificationsPressed: () => context.push(Routes.notifications),
    hasUnreadNotifications: viewModel.hasUnreadNotifications,
    isDarkMode: switch (viewModel.themePreference) {
      ThemePreference.dark => true,
      ThemePreference.light => false,
      ThemePreference.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    },
    onDarkModeChanged: viewModel.setDarkMode,
  );

  Future<void> _changePayday(BuildContext context) async {
    final day = await showPaydayPicker(context, current: viewModel.payday);
    if (day != null) viewModel.setPayday(day);
  }
}
