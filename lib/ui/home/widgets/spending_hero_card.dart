import 'package:flutter/material.dart';

import '../../../domain/models/cycle_forecast.dart';
import '../../../domain/models/cycle_spending.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/mesh_gradient_box.dart';
import 'daily_spending_bars.dart';
import 'safe_to_spend_footer.dart';

/// The top of Home: what was spent this pay cycle, how it compares with
/// the same point last cycle, each day's spending, and what is safe to
/// spend today.
class SpendingHeroCard extends StatelessWidget {
  const SpendingHeroCard({
    super.key,
    required this.spending,
    required this.forecast,
    required this.daysToPayday,
    required this.hideAmounts,
    required this.onToggleHideAmounts,
    required this.onChangePayday,
  });

  final CycleSpending spending;

  /// Null until wallets have loaded.
  final CycleForecast? forecast;
  final int daysToPayday;
  final bool hideAmounts;
  final VoidCallback onToggleHideAmounts;
  final VoidCallback onChangePayday;

  @override
  Widget build(BuildContext context) {
    final cycle = spending.cycle;
    final forecast = this.forecast;
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: context.shadows.soft,
      padding: const EdgeInsets.fromLTRB(
        Dimens.cardPadding,
        Dimens.gapM,
        Dimens.gapS,
        Dimens.cardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopRow(
            title: cycle.isCalendarMonth
                ? 'SPENT THIS MONTH'
                : 'SPENT SINCE PAYDAY',
            hideAmounts: hideAmounts,
            onToggle: onToggleHideAmounts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: Dimens.gapM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpentAmount(amount: spending.spent, hidden: hideAmounts),
                const SizedBox(height: Dimens.gapXs),
                _Comparison(
                  change: spending.change,
                  monthly: cycle.isCalendarMonth,
                  hidden: hideAmounts,
                ),
                const SizedBox(height: Dimens.gapL),
                DailySpendingBars(
                  daily: spending.daily,
                  today: spending.today,
                  start: cycle.start,
                  end: cycle.end,
                  hideAmounts: hideAmounts,
                ),
                if (forecast != null) ...[
                  const SizedBox(height: Dimens.gapL),
                  Divider(color: context.colors.navyTrack, height: 1),
                  const SizedBox(height: Dimens.gapM),
                  SafeToSpendFooter(
                    forecast: forecast,
                    daysLeft: daysToPayday,
                    hideAmounts: hideAmounts,
                    onChangePayday: onChangePayday,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.title,
    required this.hideAmounts,
    required this.onToggle,
  });

  final String title;
  final bool hideAmounts;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.textOnNavyMuted;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.text.overline.copyWith(color: muted),
          ),
        ),
        IconButton(
          onPressed: onToggle,
          tooltip: hideAmounts ? 'Show amounts' : 'Hide amounts',
          color: muted,
          iconSize: Dimens.iconSize,
          icon: AnimatedSwitcher(
            duration: AppMotion.short,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              hideAmounts
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              key: ValueKey(hideAmounts),
            ),
          ),
        ),
      ],
    );
  }
}

/// "ZMW 7,680.00": a small muted prefix, the coral whole amount and
/// smaller decimals.
class _SpentAmount extends StatelessWidget {
  const _SpentAmount({required this.amount, required this.hidden});

  final double amount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: hidden ? 'Spent, hidden' : 'Spent ${formatZmw(amount)}',
      excludeSemantics: true,
      child: AnimatedNumber(
        value: amount,
        builder: (context, value) {
          final parts = splitMoney(value);
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
                  text: hidden ? '••••••' : parts.whole,
                  style: context.text.amountLarge.copyWith(
                    color: colors.accent,
                  ),
                ),
                if (!hidden)
                  TextSpan(
                    text: parts.decimals,
                    style: context.text.amountDecimals.copyWith(
                      color: colors.textOnNavyMuted,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}

/// "ZMW 420.00 less than this time last month", with an arrow.
class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.change,
    required this.monthly,
    required this.hidden,
  });

  final double? change;
  final bool monthly;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    final period = monthly ? 'last month' : 'last cycle';
    final (IconData icon, String text) = switch (change) {
      null => (Icons.insights_rounded, 'Nothing to compare with yet'),
      final c when c.abs() < 1 => (
        Icons.trending_flat_rounded,
        'Same as this time $period',
      ),
      final c => (
        c > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        '${hidden ? 'Some' : formatZmw(c.abs())} '
            '${c > 0 ? 'more' : 'less'} than this time $period',
      ),
    };
    final color = context.colors.textOnNavy;
    return Row(
      children: [
        Icon(icon, size: Dimens.iconSizeSmall, color: color),
        const SizedBox(width: Dimens.gapS),
        Expanded(
          child: Text(
            text,
            style: context.text.label.copyWith(color: color),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
