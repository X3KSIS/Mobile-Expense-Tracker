import 'package:flutter/material.dart';

import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/tab_header.dart';
import '../view_models/budgets_view_model.dart';
import 'budget_card.dart';
import 'budget_sheet.dart';
import 'budgets_summary_card.dart';

/// This month's budgets with how much of each has been spent.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key, required this.viewModel});

  final BudgetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) => FadeSwitcher(
            animateSize: false,
            child: viewModel.isLoading
                ? const BudgetsSkeleton(key: ValueKey('loading'))
                : RefreshIndicator(
                    key: const ValueKey('content'),
                    onRefresh: viewModel.load.execute,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        Dimens.screenPadding,
                        Dimens.gapL,
                        Dimens.screenPadding,
                        Dimens.navBarClearance(context),
                      ),
                      children: [
                        _Header(viewModel: viewModel),
                        const SizedBox(height: Dimens.sectionGap),
                        FadeSwitcher(
                          child: Column(
                            key: ValueKey((
                              viewModel.hasError,
                              viewModel.isEmpty,
                            )),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _body(context),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    if (viewModel.hasError) {
      return [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your budgets",
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: viewModel.load.execute,
        ),
      ];
    }
    if (viewModel.isEmpty) {
      return [
        EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No budgets yet',
          message: 'Set a monthly limit for a category to track spending.',
          actionLabel: 'Add budget',
          onAction: () => showBudgetSheet(context, viewModel: viewModel),
        ),
      ];
    }
    return [
      BudgetsSummaryCard(
        spent: viewModel.totalSpent,
        limit: viewModel.totalLimit,
        remaining: viewModel.totalRemaining,
        percentUsed: viewModel.totalPercentUsed,
        overCount: viewModel.overCount,
      ),
      const SizedBox(height: Dimens.sectionGap),
      for (final progress in viewModel.progress) ...[
        BudgetCard(
          progress: progress,
          onTap: () => showBudgetSheet(
            context,
            viewModel: viewModel,
            budget: progress.budget,
          ),
        ),
        const SizedBox(height: Dimens.gapM),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final BudgetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final days = viewModel.daysLeft;
    return TabHeader(
      title: 'Budgets',
      subtitle:
          '${formatMonth(viewModel.month)} · $days day${days == 1 ? '' : 's'} '
          'left',
      trailing: HeaderIconButton(
        icon: Icons.add_rounded,
        tooltip: 'Add budget',
        onPressed: () => showBudgetSheet(context, viewModel: viewModel),
      ),
    );
  }
}
