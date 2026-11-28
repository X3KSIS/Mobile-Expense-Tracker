import 'package:flutter/material.dart';

import '../../../domain/models/cycle_forecast.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/status_badge.dart';

/// The hero card's last line: what is safe to spend today with its status,
/// and the days to payday (tap to change the payday).
class SafeToSpendFooter extends StatelessWidget {
  const SafeToSpendFooter({
    super.key,
    required this.forecast,
    required this.daysLeft,
    required this.hideAmounts,
    required this.onChangePayday,
  });

  final CycleForecast forecast;
  final int daysLeft;
  final bool hideAmounts;
  final VoidCallback onChangePayday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tone, status) = switch (forecast.status) {
      ForecastStatus.onTrack => (StatusTone.success, 'On track'),
      ForecastStatus.tight => (StatusTone.warning, 'Tight'),
      ForecastStatus.short => (StatusTone.danger, 'Runs short'),
      ForecastStatus.empty => (StatusTone.danger, 'Empty'),
    };
    final until = forecast.cycle.isCalendarMonth ? 'month end' : 'payday';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safe to spend today',
                style: context.text.caption.copyWith(
                  color: colors.textOnNavyMuted,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedNumber(
                value: forecast.safePerDay,
                builder: (context, value) => Text(
                  hideAmounts ? '$currencyCode ••••' : formatZmw(value),
                  style: context.text.statValue.copyWith(
                    color: colors.textOnNavy,
                  ),
                ),
              ),
              const SizedBox(height: Dimens.gapXs),
              // The dark palette's status colours are made for navy.
              Theme(
                data: AppTheme.dark,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusMark(tone: tone, size: 14),
                    const SizedBox(width: Dimens.gapXs + 2),
                    Flexible(
                      child: Text(
                        status,
                        style: context.text.caption.copyWith(
                          color: colors.textOnNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimens.gapS),
        Flexible(
          flex: 2,
          child: Semantics(
            button: true,
            label: '$daysLeft days to $until. Change payday',
            excludeSemantics: true,
            child: InkWell(
              onTap: onChangePayday,
              borderRadius: BorderRadius.circular(Dimens.radiusButton),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: Dimens.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimens.gapS),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$daysLeft day${daysLeft == 1 ? '' : 's'} to $until',
                          style: context.text.label.copyWith(
                            color: colors.textOnNavy,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: Dimens.iconSizeSmall,
                        color: colors.textOnNavyMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
