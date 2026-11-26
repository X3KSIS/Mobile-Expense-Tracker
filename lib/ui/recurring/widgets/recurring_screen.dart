import 'package:flutter/material.dart';

import '../../../domain/models/recurring_payment.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/mesh_gradient_box.dart';
import '../../core/ui/recurring_row.dart';
import '../../core/ui/screen_header.dart';
import '../../core/ui/skeleton.dart';
import '../view_models/recurring_view_model.dart';

/// Repeat payments found in the history: what they cost each month, what
/// is due soon, then subscriptions, bills and regular spending.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key, required this.viewModel});

  final RecurringViewModel viewModel;

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
              const ScreenHeader(title: 'Regular payments'),
              const SizedBox(height: Dimens.sectionGap),
              FadeSwitcher(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final vm = viewModel;
    if (vm.isLoading) {
      return const Shimmer(
        key: ValueKey('loading'),
        child: Column(
          children: [
            SkeletonBox(height: 140, radius: Dimens.radiusCard),
            SizedBox(height: Dimens.sectionGap),
            SkeletonListCard(rows: 4),
          ],
        ),
      );
    }
    if (vm.hasError) {
      return EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: "Couldn't load your payments",
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: vm.load.execute,
      );
    }
    if (vm.isEmpty) {
      return const EmptyState(
        key: ValueKey('empty'),
        icon: Icons.event_repeat_outlined,
        title: 'No regular payments yet',
        message:
            'Once something is paid three times on a rhythm (rent, DStv, '
            'fuel every week), it shows up here.',
      );
    }
    const sections = [
      (RecurringKind.subscription, 'Subscriptions'),
      (RecurringKind.bill, 'Bills'),
      (RecurringKind.regular, 'Regular spending'),
    ];
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalCard(viewModel: vm),
        if (vm.dueSoon.isNotEmpty) ...[
          const SizedBox(height: Dimens.sectionGap),
          _Section(
            title: 'Coming up',
            subtitle: 'Due in the next few days, or not recorded yet',
            payments: vm.dueSoon,
            now: vm.now,
          ),
        ],
        for (final (kind, title) in sections)
          if (vm.ofKind(kind).isNotEmpty) ...[
            const SizedBox(height: Dimens.sectionGap),
            _Section(
              title: title,
              subtitle: '${formatZmw(vm.monthlyTotalOf(kind))} a month',
              payments: vm.ofKind(kind),
              now: vm.now,
            ),
          ],
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.viewModel});

  final RecurringViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = viewModel.payments.length;
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: context.shadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOES OUT EVERY MONTH',
            style: context.text.overline.copyWith(
              color: colors.textOnNavyMuted,
            ),
          ),
          const SizedBox(height: Dimens.gapS),
          AnimatedNumber(
            value: viewModel.monthlyTotal,
            builder: (context, value) {
              final money = splitMoney(value);
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$currencyCode ',
                      style: context.text.amountPrefix.copyWith(
                        color: colors.textOnNavyMuted,
                      ),
                    ),
                    TextSpan(
                      text: money.whole,
                      style: context.text.amountLarge.copyWith(
                        color: colors.accent,
                      ),
                    ),
                    TextSpan(
                      text: money.decimals,
                      style: context.text.amountDecimals.copyWith(
                        color: colors.textOnNavyMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Dimens.gapXs),
          Text(
            'On $count regular payment${count == 1 ? '' : 's'}, '
            'about ${formatZmw(viewModel.monthlyTotal * 12)} a year',
            style: context.text.body.copyWith(color: colors.textOnNavyMuted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.payments,
    required this.now,
  });

  final String title;
  final String subtitle;
  final List<RecurringPayment> payments;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.text.sectionTitle),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: context.text.caption),
        const SizedBox(height: Dimens.gapM),
        Container(
          padding: const EdgeInsets.all(Dimens.gapL),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimens.radiusList),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (final (i, p) in payments.indexed) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimens.gapM),
                    child: Divider(),
                  ),
                RecurringRow(payment: p, now: now),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
