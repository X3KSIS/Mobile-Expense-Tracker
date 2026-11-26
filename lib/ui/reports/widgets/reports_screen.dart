import 'package:flutter/material.dart';

import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/skeleton_screens.dart';
import '../../core/ui/tab_header.dart';
import '../../core/ui/slow_refresh.dart';
import '../view_models/reports_view_model.dart';
import 'category_breakdown.dart';
import 'habit_list.dart';
import 'month_switcher.dart';
import 'report_kpis.dart';
import 'report_section.dart';
import 'spending_heatmap.dart';
import 'spending_trend_chart.dart';

/// Monthly reports: totals, spending habits, spending by category, the
/// spending trend and a daily heatmap. The month switcher scopes
/// everything.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.viewModel});

  final ReportsViewModel viewModel;

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
                ? const ReportsSkeleton(key: ValueKey('loading'))
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
                        const TabHeader(
                          title: 'Reports',
                          subtitle: 'Where your kwacha went',
                        ),
                        const SizedBox(height: Dimens.gapL),
                        MonthSwitcher(
                          month: viewModel.month,
                          onBack: viewModel.canGoBack ? viewModel.goBack : null,
                          onForward: viewModel.canGoForward
                              ? viewModel.goForward
                              : null,
                        ),
                        const SizedBox(height: Dimens.sectionGap),
                        FadeSwitcher(
                          child: Column(
                            key: ValueKey((
                              viewModel.month,
                              viewModel.hasError,
                            )),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _body(),
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

  List<Widget> _body() {
    if (viewModel.hasError) {
      return [
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your reports",
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: viewModel.load.execute,
        ),
      ];
    }
    final month = formatMonth(viewModel.month);
    return [
      ReportKpis(current: viewModel.totals, previous: viewModel.previousTotals),
      const SizedBox(height: Dimens.sectionGap + 4),
      ReportSection(
        title: 'Your habits',
        subtitle: viewModel.isCurrentMonth
            ? 'What stands out so far this month'
            : 'What stood out in $month',
        child: HabitList(
          insights: viewModel.insights,
          month: viewModel.month,
          monthToDate: viewModel.isCurrentMonth,
        ),
      ),
      const SizedBox(height: Dimens.sectionGap + 4),
      ReportSection(
        title: 'Spending by category',
        subtitle: 'Where the money went in $month',
        child: CategoryBreakdown(categories: viewModel.categories),
      ),
      const SizedBox(height: Dimens.sectionGap + 4),
      ReportSection(
        title: 'Spending trend',
        subtitle: 'Last ${viewModel.trendLength} months · tap a month',
        child: SpendingTrendChart(
          months: viewModel.trend,
          selected: viewModel.month,
          onSelected: viewModel.selectMonth,
        ),
      ),
      const SizedBox(height: Dimens.sectionGap + 4),
      ReportSection(
        title: 'Daily spending',
        subtitle: 'How much you spent each day in $month',
        child: SpendingHeatmap(
          days: viewModel.days,
          selected: viewModel.selectedDay,
          isFuture: viewModel.isFuture,
          onSelected: viewModel.selectDay,
        ),
      ),
    ];
  }
}
