import 'package:flutter/material.dart';

import '../../../domain/models/category_trend.dart';
import '../../../domain/models/transaction.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/transaction_details_sheet.dart';
import '../../core/ui/transaction_row.dart';
import '../../reports/view_models/reports_view_model.dart';
import '../../reports/widgets/report_section.dart';
import '../../reports/widgets/spending_trend_chart.dart';
import '../view_models/category_trend_view_model.dart';
import 'place_list.dart';
import 'trend_summary_card.dart';

/// One category over time: what was spent in the selected month against a
/// usual month, the last few months, where the money went and the
/// payments themselves.
class CategoryTrendScreen extends StatefulWidget {
  const CategoryTrendScreen({super.key, required this.viewModel});

  final CategoryTrendViewModel viewModel;

  @override
  State<CategoryTrendScreen> createState() => _CategoryTrendScreenState();
}

class _CategoryTrendScreenState extends State<CategoryTrendScreen> {
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
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([vm, vm.load]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              ScreenHeader(title: vm.categoryName),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final vm = widget.viewModel;
    if (vm.isLoading) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: Column(
          children: [
            SkeletonBox(height: 150, radius: Dimens.radiusCard),
            SizedBox(height: Dimens.sectionGap),
            SkeletonBox(height: 200, radius: Dimens.radiusList),
          ],
        ),
      );
    }
    if (vm.hasError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load this category",
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: vm.load.execute,
      );
    }
    final trend = vm.trend;
    if (trend == null) {
      return EmptyState(
        key: const ValueKey('empty'),
        icon: Icons.insights_outlined,
        title: 'Nothing spent here lately',
        message:
            'No ${vm.categoryName} spending in the last ${vm.length} months.',
      );
    }
    return _TrendContent(
      key: const ValueKey('content'),
      trend: trend,
      now: vm.now,
      onMonthSelected: vm.selectMonth,
      onTransactionTap: _openDetails,
    );
  }
}

class _TrendContent extends StatelessWidget {
  const _TrendContent({
    super.key,
    required this.trend,
    required this.now,
    required this.onMonthSelected,
    required this.onTransactionTap,
  });

  final CategoryTrend trend;
  final DateTime now;
  final ValueChanged<DateTime> onMonthSelected;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final month = formatMonth(trend.month);
    final peak = trend.peak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrendSummaryCard(trend: trend),
        const SizedBox(height: Dimens.sectionGap + 4),
        ReportSection(
          title: 'Last ${trend.months.length} months',
          subtitle: peak == null
              ? 'Tap a month'
              : 'Most in ${formatMonth(peak.month)} '
                    '(${formatZmw(peak.amount)}) · tap a month',
          child: SpendingTrendChart(
            months: [
              for (final m in trend.months)
                MonthTotals(month: m.month, income: 0, expenses: m.amount),
            ],
            selected: trend.month,
            onSelected: onMonthSelected,
          ),
        ),
        const SizedBox(height: Dimens.sectionGap + 4),
        FadeSwitcher(
          child: Column(
            key: ValueKey(trend.month),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: trend.transactions.isEmpty
                ? [
                    EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'Nothing spent in $month',
                      message: 'Pick another month on the chart.',
                    ),
                  ]
                : [
                    ReportSection(
                      title: 'Where it went',
                      subtitle: 'Places you paid in $month',
                      child: PlaceList(places: trend.places),
                    ),
                    const SizedBox(height: Dimens.sectionGap + 4),
                    _TransactionList(
                      month: month,
                      transactions: trend.transactions,
                      now: now,
                      onTap: onTransactionTap,
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.month,
    required this.transactions,
    required this.now,
    required this.onTap,
  });

  final String month;
  final List<Transaction> transactions;
  final DateTime now;
  final ValueChanged<Transaction> onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Payments', style: textTheme.titleMedium),
        ),
        const SizedBox(height: 2),
        Text('Everything in $month, newest first', style: textTheme.bodySmall),
        const SizedBox(height: Dimens.gapM),
        ListCard(
          children: [
            for (final t in transactions)
              TransactionRow(transaction: t, now: now, onTap: () => onTap(t)),
          ],
        ),
      ],
    );
  }
}
