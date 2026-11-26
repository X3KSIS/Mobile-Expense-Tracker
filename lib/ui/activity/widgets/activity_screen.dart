import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/transaction.dart';
import '../../../routing/routes.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/search_box.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/stat_tile.dart';
import '../../core/ui/tab_header.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../../core/ui/slow_refresh.dart';
import '../view_models/activity_view_model.dart';
import 'activity_day_section.dart';
import 'activity_filter_toggle.dart';
import 'see_all_button.dart';

/// The last week of transactions, filterable and grouped by day, with a
/// way into the full History. The search box opens the full-screen search.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.viewModel});

  final ActivityViewModel viewModel;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.delete.addListener(_onDeleteChanged);
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.delete.removeListener(_onDeleteChanged);
      widget.viewModel.delete.addListener(_onDeleteChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.delete.removeListener(_onDeleteChanged);
    super.dispose();
  }

  void _onDeleteChanged() {
    final delete = widget.viewModel.delete;
    if (delete.running || delete.result == null || !mounted) return;
    final message = delete.completed
        ? 'Transaction deleted'
        : "Couldn't delete. Please try again.";
    delete.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDetails(Transaction transaction) {
    showTransactionDetails(
      context,
      transaction: transaction,
      onDelete: () => widget.viewModel.delete.execute(transaction.id),
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
          builder: (context, _) => FadeSwitcher(
            animateSize: false,
            child: viewModel.isLoading
                ? const ActivitySkeleton(key: ValueKey('loading'))
                : SlowRefresh(
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
                        _ActivityHeader(viewModel: viewModel),
                        const SizedBox(height: Dimens.sectionGap),
                        FadeSwitcher(
                          child: Column(
                            // The filter is not part of the key: changing it
                            // folds rows in and out rather than swapping
                            // the whole list.
                            key: ValueKey((
                              viewModel.hasError,
                              viewModel.isEmpty,
                              viewModel.hasNoRecent,
                              viewModel.hasNoMatches,
                            )),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _body(viewModel),
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

  List<Widget> _body(ActivityViewModel viewModel) {
    if (viewModel.hasError) {
      return [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your activity",
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: viewModel.load.execute,
        ),
      ];
    }
    if (viewModel.isEmpty) {
      return [
        EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet',
          message: 'Tap + to record your first expense or income.',
          actionLabel: 'Add transaction',
          onAction: () => context.push(Routes.add),
        ),
      ];
    }
    final seeAll = SeeAllButton(
      total: viewModel.totalCount,
      onTap: () => context.push(Routes.history),
    );
    if (viewModel.hasNoRecent) {
      return [
        const EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'Quiet week',
          message: 'Nothing recorded in the last 7 days.',
        ),
        const SizedBox(height: Dimens.gapL),
        seeAll,
      ];
    }
    if (viewModel.hasNoMatches) {
      return [
        const EmptyState(
          icon: Icons.filter_list_off_rounded,
          title: 'Nothing here this week',
          message: 'No recent transactions match this filter.',
        ),
        const SizedBox(height: Dimens.gapL),
        seeAll,
      ];
    }
    return [
      for (final day in viewModel.allDays)
        ActivityDaySection(
          key: ValueKey(day.day),
          day: day,
          isVisible: viewModel.isVisible,
          onTransactionTap: _openDetails,
        ),
      seeAll,
    ];
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.viewModel});

  final ActivityViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final count = viewModel.visibleCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedNumber(
          value: count.toDouble(),
          builder: (context, value) {
            final shown = value.round();
            return TabHeader(
              title: 'Activity',
              subtitle:
                  'Last ${ActivityViewModel.recentDays} days · $shown '
                  'transaction${shown == 1 ? '' : 's'}',
            );
          },
        ),
        const SizedBox(height: Dimens.gapL),
        SearchLauncher(
          hint: 'Search transactions',
          onTap: () => context.push(Routes.search),
        ),
        const SizedBox(height: Dimens.gapM),
        ActivityFilterToggle(
          selected: viewModel.filter,
          onChanged: viewModel.setFilter,
        ),
        const SizedBox(height: Dimens.gapM),
        Row(
          children: [
            Expanded(
              child: AnimatedNumber(
                value: viewModel.totalIn,
                builder: (context, value) => StatTile(
                  label: 'Money in',
                  value: formatZmw(value),
                  icon: Icons.south_west_rounded,
                  valueColor: context.colors.success,
                ),
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: AnimatedNumber(
                value: viewModel.totalOut,
                builder: (context, value) => StatTile(
                  label: 'Money out',
                  value: formatZmw(value),
                  icon: Icons.north_east_rounded,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
