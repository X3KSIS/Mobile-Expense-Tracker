import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/transaction.dart';
import '../../../routing/routes.dart';
import '../../activity/widgets/activity_filter_toggle.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../view_models/history_view_model.dart';
import 'history_month_section.dart';

/// Every transaction, month by month, filterable by type.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.viewModel});

  final HistoryViewModel viewModel;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.delete.addListener(_onDeleteChanged);
  }

  @override
  void dispose() {
    widget.viewModel.delete.removeListener(_onDeleteChanged);
    super.dispose();
  }

  void _onDeleteChanged() {
    final delete = widget.viewModel.delete;
    if (delete.running || delete.result == null || !mounted) return;
    final deleted = delete.completed;
    delete.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Transaction deleted'
                : "Couldn't delete. Please try again.",
          ),
          action: deleted
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: widget.viewModel.undoDelete.execute,
                )
              : null,
        ),
      );
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
    final vm = widget.viewModel;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.load]),
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  Dimens.gapL,
                  Dimens.screenPadding,
                  Dimens.sectionGap,
                ),
                sliver: SliverToBoxAdapter(child: _Header(viewModel: vm)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  Dimens.screenPadding,
                  0,
                  Dimens.screenPadding,
                  Dimens.screenPadding + bottom,
                ),
                sliver: _state(vm) ?? _months(vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading, error and empty states, or null when there is a list.
  Widget? _state(HistoryViewModel vm) {
    final Widget child;
    if (vm.isLoading) {
      child = const Shimmer(
        key: ValueKey('loading'),
        child: Column(
          children: [
            SkeletonBox(height: 52, radius: Dimens.radiusTile),
            SizedBox(height: Dimens.gapM),
            SkeletonListCard(rows: 5),
          ],
        ),
      );
    } else if (vm.hasError) {
      child = EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your history",
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: vm.load.execute,
      );
    } else if (vm.isEmpty) {
      child = const EmptyState(
        key: ValueKey('empty'),
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        message: 'Everything you record shows up here, month by month.',
      );
    } else {
      return null;
    }
    return SliverToBoxAdapter(child: FadeSwitcher(child: child));
  }

  Widget _months(HistoryViewModel vm) {
    final months = vm.months;
    return SliverList.builder(
      itemCount: months.length + 1,
      itemBuilder: (context, index) {
        // The last item says when nothing matches, so the list itself never
        // swaps out and rows fold away in place.
        if (index == months.length) {
          return FadeSwitcher(
            child: vm.hasNoMatches
                ? const EmptyState(
                    key: ValueKey('none'),
                    icon: Icons.filter_list_off_rounded,
                    title: 'Nothing here',
                    message: 'No transactions match this filter.',
                  )
                : const SizedBox(key: ValueKey('some'), width: double.infinity),
          );
        }
        return HistoryMonthSection(
          key: ValueKey(months[index].month),
          month: months[index],
          viewModel: vm,
          onTransactionTap: _openDetails,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'History',
          trailing: HeaderIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search transactions',
            onPressed: () => context.push(Routes.search),
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        AnimatedNumber(
          value: viewModel.visibleCount.toDouble(),
          builder: (context, value) {
            final shown = value.round();
            return Text(
              '$shown transaction${shown == 1 ? '' : 's'}',
              style: context.text.label,
            );
          },
        ),
        const SizedBox(height: Dimens.gapL),
        ActivityFilterToggle(
          selected: viewModel.filter,
          onChanged: viewModel.setFilter,
        ),
      ],
    );
  }
}
