import 'package:flutter/material.dart';

import '../../../domain/models/category_trend.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/mesh_gradient_box.dart';

/// How [trend]'s month compares with a usual month, in words.
String describeComparison(CategoryTrend trend) {
  final usual = trend.usual;
  final change = trend.change;
  final byNow = trend.monthToDate ? ' by this date' : '';
  final months = trend.usualMonths == 1
      ? 'the month before'
      : 'the ${trend.usualMonths} months before';
  if (usual == null || change == null) {
    return trend.monthToDate
        ? 'Nothing earlier to compare with yet'
        : 'No spending here in the months before';
  }
  if (change.abs() < CategoryTrends.steadyTolerance) {
    return 'About the same as usual$byNow '
        '(${formatZmw(usual)}, the average of $months)';
  }
  final difference = trend.difference!.abs();
  final percent = (change.abs() * 100).round();
  final direction = change > 0 ? 'more' : 'less';
  return '${formatZmw(difference)} ($percent%) $direction than usual$byNow. '
      'A usual month is ${formatZmw(usual)}, the average of $months.';
}

/// Navy card with what was spent in the category this month and how it
/// compares with a usual month.
class TrendSummaryCard extends StatelessWidget {
  const TrendSummaryCard({super.key, required this.trend});

  final CategoryTrend trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = formatMonth(trend.month).toUpperCase();
    final overline = trend.monthToDate
        ? 'SPENT SO FAR IN $month'
        : 'SPENT IN $month';
    final count = trend.transactions.length;
    return MeshGradientBox(
      mesh: context.gradients.navyMesh,
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      boxShadow: context.shadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: context.text.overline.copyWith(
              color: colors.textOnNavyMuted,
            ),
          ),
          const SizedBox(height: Dimens.gapS),
          AnimatedNumber(
            value: trend.spent,
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
            'Across $count payment${count == 1 ? '' : 's'}',
            style: context.text.caption.copyWith(color: colors.textOnNavyMuted),
          ),
          const SizedBox(height: Dimens.gapM),
          Text(
            describeComparison(trend),
            style: context.text.body.copyWith(color: colors.textOnNavy),
          ),
        ],
      ),
    );
  }
}
