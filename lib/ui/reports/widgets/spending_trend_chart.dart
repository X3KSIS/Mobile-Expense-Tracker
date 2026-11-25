import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../view_models/reports_view_model.dart';

/// Column chart of monthly spending. The selected month is the coral
/// emphasis mark and carries the only value label; the other months are
/// muted context. Tapping a column selects that month.
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelected,
  });

  final List<MonthTotals> months;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  static const double _axisWidth = 36;
  static const double _labelRoom = 20;

  /// Rounds [value] up to a clean axis maximum (1, 1.2, 1.5, 2, 2.5, 3, 4,
  /// 5, 6 or 8 times a power of ten), so the tallest column fills most of
  /// the plot.
  static double niceCeiling(double value) {
    if (value <= 0) return 1000;
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    for (final step in const [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
      if (step * magnitude >= value) return step * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final top = niceCeiling(months.map((m) => m.expenses).fold(0.0, math.max));
    const plotHeight = Dimens.chartHeight - _labelRoom;
    return Column(
      children: [
        SizedBox(
          height: Dimens.chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YAxis(top: top, plotHeight: plotHeight),
              Expanded(
                child: Stack(
                  children: [
                    _Gridlines(plotHeight: plotHeight),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final m in months)
                          Expanded(
                            child: _Column(
                              totals: m,
                              selected: m.month == selected,
                              height: plotHeight * (m.expenses / top),
                              onTap: () => onSelected(m.month),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        Row(
          children: [
            const SizedBox(width: _axisWidth),
            for (final m in months)
              Expanded(
                child: Text(
                  formatMonthShort(m.month),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: m.month == selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: m.month == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _YAxis extends StatelessWidget {
  const _YAxis({required this.top, required this.plotHeight});

  final double top;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: SpendingTrendChart._axisWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final fraction in const [0.0, 0.5, 1.0])
              Positioned(
                left: 0,
                right: Dimens.gapS,
                bottom: plotHeight * fraction - 7,
                child: Text(
                  formatCompact(top * fraction),
                  style: AppTypography.caption,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Gridlines extends StatelessWidget {
  const _Gridlines({required this.plotHeight});

  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          for (final fraction in const [0.0, 0.5, 1.0])
            Positioned(
              left: 0,
              right: 0,
              bottom: plotHeight * fraction,
              child: const ColoredBox(
                color: AppColors.chartGrid,
                child: SizedBox(height: 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.totals,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final MonthTotals totals;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${formatMonthYear(totals.month)}: spent '
          '${formatZmw(totals.expenses)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(bottom: Dimens.gapXs),
                child: Text(
                  formatCompact(totals.expenses),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: Dimens.columnMaxWidth,
              height: math.max(height, totals.expenses > 0 ? 2 : 0),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.chartMuted,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimens.dataEndRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
