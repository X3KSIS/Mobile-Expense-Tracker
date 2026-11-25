import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/transaction.dart';
import '../../../routing/routes.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/segmented_toggle.dart';
import '../../core/ui/stat_tile.dart';
import '../../core/ui/tab_header.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../view_models/activity_view_model.dart';
import 'activity_day_section.dart';
import 'activity_search_field.dart';

/// Every transaction, searchable and filterable, grouped by day.
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
                        _ActivityHeader(viewModel: viewModel),
                        const SizedBox(height: Dimens.sectionGap),
                        FadeSwitcher(
                          child: Column(
                            key: ValueKey((
                              viewModel.filter,
                              viewModel.hasError,
                              viewModel.isEmpty,
                              viewModel.days.isEmpty,
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
    if (viewModel.days.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try a different search or filter.',
        ),
      ];
    }
    return [
      for (final day in viewModel.days) ...[
        ActivityDaySection(day: day, onTransactionTap: _openDetails),
        const SizedBox(height: Dimens.sectionGap),
      ],
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
        TabHeader(
          title: 'Activity',
          subtitle: '$count transaction${count == 1 ? '' : 's'}',
        ),
        const SizedBox(height: Dimens.gapL),
        ActivitySearchField(
          initialQuery: viewModel.query,
          onChanged: viewModel.setQuery,
        ),
        const SizedBox(height: Dimens.gapM),
        SegmentedToggle<ActivityFilter>(
          options: const [
            ToggleOption(value: ActivityFilter.all, label: 'All'),
            ToggleOption(value: ActivityFilter.expenses, label: 'Expenses'),
            ToggleOption(value: ActivityFilter.income, label: 'Income'),
          ],
          selected: viewModel.filter,
          onChanged: viewModel.setFilter,
        ),
        const SizedBox(height: Dimens.gapM),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Money in',
                value: formatZmw(viewModel.totalIn),
                icon: Icons.south_west_rounded,
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: Dimens.gapM),
            Expanded(
              child: StatTile(
                label: 'Money out',
                value: formatZmw(viewModel.totalOut),
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
