import 'package:flutter/material.dart';

import '../../../domain/models/monthly_summary.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';

/// Net balance for the month with income and expense tiles.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.summary,
    required this.hideAmounts,
    required this.onToggleHideAmounts,
  });

  final MonthlySummary summary;
  final bool hideAmounts;
  final VoidCallback onToggleHideAmounts;

  static const String _mask = '••••';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Net balance · ${formatMonth(summary.month)}',
                    style: textTheme.labelMedium,
                  ),
                ),
                IconButton(
                  onPressed: onToggleHideAmounts,
                  tooltip: hideAmounts ? 'Show amounts' : 'Hide amounts',
                  color: context.colors.textSecondary,
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
            ),
            FadeSwitcher(
              alignment: Alignment.centerLeft,
              child: _NetAmount(
                key: ValueKey((summary.net, hideAmounts)),
                amount: summary.net,
                hidden: hideAmounts,
              ),
            ),
            const SizedBox(height: Dimens.gapL),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'INCOME',
                    value: hideAmounts
                        ? _mask
                        : '+${formatWhole(summary.income)}',
                    valueColor: context.colors.success,
                  ),
                ),
                const SizedBox(width: Dimens.gapM),
                Expanded(
                  child: _StatTile(
                    label: 'EXPENSES',
                    value: hideAmounts
                        ? _mask
                        : '-${formatWhole(summary.expenses)}',
                    valueColor: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "ZMW 4,820.00" with a small grey prefix and smaller, lighter decimals.
class _NetAmount extends StatelessWidget {
  const _NetAmount({super.key, required this.amount, required this.hidden});

  final double amount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final parts = splitMoney(amount);
    return Semantics(
      label: hidden ? 'Net balance hidden' : 'Net balance ${formatZmw(amount)}',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$currencyCode ', style: context.text.amountPrefix),
            TextSpan(
              text: hidden ? '••••••' : parts.whole,
              style: context.text.amountLarge,
            ),
            if (!hidden)
              TextSpan(
                text: parts.decimals,
                style: context.text.amountDecimals,
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.gapL,
        vertical: Dimens.gapM,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Dimens.radiusTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.overline),
          const SizedBox(height: Dimens.gapXs),
          FadeSwitcher(
            alignment: Alignment.centerLeft,
            duration: AppMotion.short,
            child: Text(
              value,
              key: ValueKey(value),
              style: context.text.statValue.copyWith(color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
