import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';

/// One thin column per day of the pay cycle, on the navy hero card.
///
/// Emphasis form, one series: today is the coral mark, earlier days are
/// muted context, days still to come are a faint stub. The first and last
/// day label the ends; a screen reader hears a one-line summary instead.
class DailySpendingBars extends StatelessWidget {
  const DailySpendingBars({
    super.key,
    required this.daily,
    required this.today,
    required this.start,
    required this.end,
    required this.hideAmounts,
  });

  final List<double> daily;
  final int today;

  /// First day of the cycle, and the day after its last.
  final DateTime start;
  final DateTime end;
  final bool hideAmounts;

  static const double _height = 56;
  static const double _stub = 2;
  static const double _gap = 2;

  String _summary() {
    final spentDays = [
      for (var i = 0; i <= today && i < daily.length; i++)
        if (daily[i] > 0) daily[i],
    ];
    if (spentDays.isEmpty) return 'No spending yet this cycle';
    final biggest = spentDays.reduce(math.max);
    return 'Spent on ${spentDays.length} of ${today + 1} days so far'
        '${hideAmounts ? '' : ', most in a day ${formatZmw(biggest)}'}'
        ', today ${hideAmounts ? 'hidden' : formatZmw(daily[today])}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = daily.fold(0.0, math.max);
    final muted = colors.textOnNavyMuted.withValues(alpha: 0.55);
    final labelStyle = context.text.caption.copyWith(
      color: colors.textOnNavyMuted,
    );
    return Semantics(
      label: _summary(),
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: _height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < daily.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == daily.length - 1 ? 0 : _gap,
                      ),
                      child: _Bar(
                        height: i > today || top <= 0
                            ? _stub
                            : math.max(_stub, _height * daily[i] / top),
                        color: i == today
                            ? colors.accent
                            : i > today
                            ? colors.navyTrack
                            : muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.gapXs),
          Row(
            children: [
              Text(formatDayMonth(start), style: labelStyle),
              const Spacer(),
              Text(
                formatDayMonth(end.subtract(const Duration(days: 1))),
                style: labelStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.long,
      curve: AppMotion.enter,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimens.dataEndRadius),
        ),
      ),
    );
  }
}
