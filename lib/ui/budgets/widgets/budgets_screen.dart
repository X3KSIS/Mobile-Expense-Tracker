import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/slow_refresh.dart';
import '../../core/ui/tab_header.dart';
import '../view_models/budgets_view_model.dart';
import 'budget_card.dart';
import 'budget_sheet.dart';
import 'budgets_summary_card.dart';

/// This month's budgets with how much of each has been spent. Cards expand
/// on tap, and a long press lifts a card so it can be dragged into a new
/// place while the others slide out of its way.
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
                : SlowRefresh(
                    key: const ValueKey('content'),
                    onRefresh: viewModel.load.execute,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            Dimens.screenPadding,
                            Dimens.gapL,
                            Dimens.screenPadding,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _TopSection(viewModel: viewModel),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            Dimens.screenPadding,
                            0,
                            Dimens.screenPadding,
                            Dimens.navBarClearance(context),
                          ),
                          sliver: _BudgetList(viewModel: viewModel),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Header, then the error or empty state, or the summary card.
class _TopSection extends StatelessWidget {
  const _TopSection({required this.viewModel});

  final BudgetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(viewModel: viewModel),
        const SizedBox(height: Dimens.sectionGap),
        FadeSwitcher(
          child: KeyedSubtree(
            key: ValueKey((viewModel.hasError, viewModel.isEmpty)),
            child: _body(context),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your budgets",
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: viewModel.load.execute,
      );
    }
    if (viewModel.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No budgets yet',
        message: 'Set a monthly limit for a category to track spending.',
        actionLabel: 'Add budget',
        onAction: () => showBudgetSheet(context, viewModel: viewModel),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.sectionGap),
      child: BudgetsSummaryCard(
        spent: viewModel.totalSpent,
        limit: viewModel.totalLimit,
        remaining: viewModel.totalRemaining,
        percentUsed: viewModel.totalPercentUsed,
        overCount: viewModel.overCount,
      ),
    );
  }
}

/// The budget cards. Long-press one to drag it to a new place.
class _BudgetList extends StatelessWidget {
  const _BudgetList({required this.viewModel});

  final BudgetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = viewModel.hasError ? const [] : viewModel.progress;
    return SliverReorderableList(
      itemCount: items.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: (from, to) => viewModel.reorder.execute((from, to)),
      proxyDecorator: _lifted,
      itemBuilder: (context, index) {
        final progress = viewModel.progress[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(progress.budget.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Dimens.gapM),
            child: BudgetCard(
              progress: progress,
              dailyAllowance: viewModel.dailyAllowance(progress),
              dailyAverage: viewModel.dailyAverage(progress),
              onEdit: () => showBudgetSheet(
                context,
                viewModel: viewModel,
                budget: progress.budget,
              ),
            ),
          ),
        );
      },
    );
  }

  /// The dragged card grows by 5 % and lifts onto a soft shadow.
  Widget _lifted(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = AppMotion.enter.transform(animation.value);
        return Transform.scale(
          scale: lerpDouble(1, AppMotion.dragLiftScale, t),
          child: Stack(
            children: [
              // The shadow matches the card, not its bottom spacing.
              Positioned.fill(
                bottom: Dimens.gapM,
                child: Opacity(
                  opacity: t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimens.radiusList),
                      boxShadow: context.shadows.soft,
                    ),
                  ),
                ),
              ),
              Material(type: MaterialType.transparency, child: child),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final BudgetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final days = viewModel.daysLeft;
    final cycle = viewModel.cycle;
    final lastDay = cycle.end.subtract(const Duration(days: 1));
    final period = cycle.isCalendarMonth
        ? formatMonth(cycle.start)
        : '${formatDayMonth(cycle.start)} to ${formatDayMonth(lastDay)}';
    return TabHeader(
      title: 'Budgets',
      subtitle: '$period · $days day${days == 1 ? '' : 's'} left',
      trailing: HeaderIconButton(
        icon: Icons.add_rounded,
        tooltip: 'Add budget',
        onPressed: () => showBudgetSheet(context, viewModel: viewModel),
      ),
    );
  }
}
