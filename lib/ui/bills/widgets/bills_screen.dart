import 'package:flutter/material.dart';

import '../../../domain/models/bill.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_icon.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/list_card.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../view_models/bills_view_model.dart';
import 'bill_actions_sheet.dart';
import 'bill_form_sheet.dart';
import 'bill_row.dart';

/// Bills the user is reminded about: overdue ones first (they stay until
/// marked paid), then those due within a week, then the rest, and
/// regular payments spotted in the spending that could become bills.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key, required this.viewModel});

  final BillsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.load]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              ScreenHeader(
                title: 'Bills',
                trailing: HeaderIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add bill',
                  onPressed: () => showBillForm(context, viewModel: viewModel),
                ),
              ),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.isLoading) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: SkeletonListCard(rows: 3),
      );
    }
    if (viewModel.hasError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your bills",
        message: 'Please try again.',
        actionLabel: 'Try again',
        onAction: viewModel.load.execute,
      );
    }
    final suggestions = viewModel.suggestions;
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewModel.bills.isEmpty)
          EmptyState(
            icon: Icons.event_repeat_rounded,
            title: 'No bills yet',
            message:
                'Add rent, DStv or school fees to be reminded a week '
                'before, 3 days before and on the day.',
            actionLabel: 'Add bill',
            onAction: () => showBillForm(context, viewModel: viewModel),
          )
        else ...[
          _Summary(viewModel: viewModel),
          ..._section(context, 'Overdue', viewModel.overdue),
          ..._section(context, 'Due this week', viewModel.dueSoon),
          ..._section(context, 'Later', viewModel.later),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          _Suggestions(viewModel: viewModel, suggestions: suggestions),
        ],
      ],
    );
  }

  List<Widget> _section(BuildContext context, String title, List<Bill> bills) {
    if (bills.isEmpty) return const [];
    return [
      const SizedBox(height: Dimens.sectionGap),
      Padding(
        padding: const EdgeInsets.only(left: Dimens.gapXs, bottom: Dimens.gapS),
        child: Semantics(
          header: true,
          child: Text(title.toUpperCase(), style: context.text.overline),
        ),
      ),
      ListCard(
        children: [
          for (final bill in bills)
            BillRow(
              key: ValueKey(bill.id),
              bill: bill,
              now: viewModel.now,
              onTap: () =>
                  showBillActions(context, viewModel: viewModel, bill: bill),
            ),
        ],
      ),
    ];
  }
}

/// What the bills cost a month, and what is overdue.
class _Summary extends StatelessWidget {
  const _Summary({required this.viewModel});

  final BillsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overdue = viewModel.overdue.length;
    final count = viewModel.bills.length;
    return Container(
      padding: const EdgeInsets.all(Dimens.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BILLS A MONTH', style: context.text.overline),
          const SizedBox(height: Dimens.gapXs),
          Text(
            formatZmw(viewModel.monthlyTotal),
            style: context.text.amountMedium,
          ),
          const SizedBox(height: Dimens.gapXs),
          Text(
            overdue == 0
                ? '$count bill${count == 1 ? '' : 's'} · nothing overdue'
                : '$overdue overdue · ${formatZmw(viewModel.overdueTotal)} '
                      'to pay',
            style: context.text.label.copyWith(
              color: overdue == 0 ? colors.textSecondary : colors.error,
              fontWeight: overdue == 0 ? null : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Regular payments found in the spending, each one tap from a bill.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.viewModel, required this.suggestions});

  final BillsViewModel viewModel;
  final List<BillDraft> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Spotted in your spending',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimens.gapXs),
        Text(
          'Regular payments you could be reminded about.',
          style: context.text.label,
        ),
        const SizedBox(height: Dimens.gapM),
        ListCard(
          children: [
            for (final s in suggestions)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimens.gapL,
                  Dimens.gapM,
                  Dimens.gapS,
                  Dimens.gapM,
                ),
                child: Row(
                  children: [
                    IconTile(
                      icon: CategoryIcons.resolve(s.category?.icon ?? 'other'),
                    ),
                    const SizedBox(width: Dimens.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: context.text.listTitle),
                          Text(
                            '${formatZmw(s.amount)} · ${cadenceName(s.cadence)}',
                            style: context.text.caption,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          showBillForm(context, viewModel: viewModel, draft: s),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
