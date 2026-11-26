import 'package:flutter/material.dart';

import '../../../domain/models/cycle_forecast.dart';
import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/status_badge.dart';

/// How much can be spent today so the money lasts to payday, whether it
/// will at the current pace, and the payday (tap to change it).
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({
    super.key,
    required this.forecast,
    required this.payday,
    required this.daysLeft,
    required this.hideAmounts,
    required this.onChangePayday,
  });

  final CycleForecast forecast;

  /// Day of the month pay arrives.
  final int payday;

  /// Days to the next payday, counting today.
  final int daysLeft;
  final bool hideAmounts;
  final VoidCallback onChangePayday;

  static const String _mask = '••••';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = daysLeft;
    final until = forecast.cycle.isCalendarMonth
        ? 'month end'
        : 'payday (${formatDayMonth(forecast.payday)})';
    return Container(
      padding: const EdgeInsets.all(Dimens.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SAFE TO SPEND TODAY',
                  style: context.text.overline,
                ),
              ),
              _Status(forecast: forecast),
            ],
          ),
          const SizedBox(height: Dimens.gapS),
          AnimatedNumber(
            value: forecast.safePerDay,
            builder: (context, value) => Text(
              hideAmounts ? '$currencyCode $_mask' : formatZmw(value),
              style: context.text.amountMedium,
            ),
          ),
          const SizedBox(height: Dimens.gapXs),
          Text(
            '$days day${days == 1 ? '' : 's'} to $until',
            style: context.text.label,
          ),
          const SizedBox(height: Dimens.gapM),
          const Divider(),
          const SizedBox(height: Dimens.gapS),
          Row(
            children: [
              Expanded(
                child: Text(_pace(), style: context.text.caption, maxLines: 2),
              ),
              TextButton.icon(
                onPressed: onChangePayday,
                icon: const Icon(
                  Icons.event_outlined,
                  size: Dimens.iconSizeSmall,
                ),
                label: Text('Payday ${ordinal(payday)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pace() {
    final average = hideAmounts ? _mask : formatZmw(forecast.averagePerDay);
    final runsOut = forecast.runsOutOn;
    return switch (forecast.status) {
      ForecastStatus.empty => 'Nothing left in your wallets.',
      ForecastStatus.onTrack when runsOut == null => 'No spending yet.',
      ForecastStatus.onTrack => 'At $average a day, it lasts to payday.',
      ForecastStatus.tight || ForecastStatus.short =>
        'At $average a day, it runs out on ${formatDayMonth(runsOut!)}.',
    };
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.forecast});

  final CycleForecast forecast;

  @override
  Widget build(BuildContext context) {
    final (tone, label) = switch (forecast.status) {
      ForecastStatus.onTrack => (StatusTone.success, 'On track'),
      ForecastStatus.tight => (StatusTone.warning, 'Tight'),
      ForecastStatus.short => (StatusTone.danger, 'Runs short'),
      ForecastStatus.empty => (StatusTone.danger, 'Empty'),
    };
    return StatusBadge(tone: tone, label: label);
  }
}
