import 'package:flutter/material.dart';

import '../../../domain/models/budget_progress.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/expandable_section.dart';
import '../../core/ui/stat_tile.dart';
import '../../core/ui/status_badge.dart';
import 'budget_bar.dart';

/// One budget: category, what is left (or over), a bar with a "today"
/// marker, how spending compares with an even pace, and a status badge.
///
/// Tapping the card expands it (350 ms, ease out) to show what can be
/// spent per day, the daily average and an edit button.
class BudgetCard extends StatefulWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    required this.planned,
    required this.cycleFraction,
    required this.dailyAllowance,
    required this.dailyAverage,
    required this.onEdit,
  });

  final BudgetProgress progress;

  /// What would have been spent by today at an even pace.
  final double planned;

  /// How far through the cycle today is, 0 to 1.
  final double cycleFraction;

  /// What can still be spent each day for the rest of the cycle.
  final double dailyAllowance;

  /// Average spent per day so far this cycle.
  final double dailyAverage;
  final VoidCallback onEdit;

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = widget.progress;
    final radius = BorderRadius.circular(Dimens.radiusList);
    return Semantics(
      expanded: _expanded,
      hint: _expanded ? 'Hides details' : 'Shows details',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(Dimens.gapL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(progress: progress, expanded: _expanded),
                const SizedBox(height: Dimens.gapM),
                BudgetBar(
                  value: progress.percentUsed,
                  planned: widget.cycleFraction,
                  color: progress.needsAttention
                      ? colors.accentStrong
                      : colors.accent,
                  markerColor: colors.textPrimary,
                  semanticLabel:
                      '${progress.budget.categoryName}: '
                      '${progress.percentRounded}% used, '
                      '${(widget.cycleFraction * 100).round()}% of the '
                      'cycle gone',
                ),
                const SizedBox(height: Dimens.gapS),
                _PaceRow(progress: progress, planned: widget.planned),
                ExpandableSection(
                  expanded: _expanded,
                  child: _Details(
                    dailyAllowance: widget.dailyAllowance,
                    dailyAverage: widget.dailyAverage,
                    onEdit: widget.onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon, name and "ZMW 3,200 of ZMW 3,300", with what is left on the
/// right.
class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.expanded});

  final BudgetProgress progress;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final budget = progress.budget;
    final over = progress.isOverLimit;
    return Row(
      children: [
        CategoryTile(icon: budget.categoryIcon),
        const SizedBox(width: Dimens.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.categoryName,
                style: context.text.listTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$currencyCode ${formatWhole(progress.spent)} of '
                '${formatWhole(budget.limit)}',
                style: context.text.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimens.gapS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatZmw(over ? progress.overBy : progress.remaining),
              style: context.text.listAmount.copyWith(
                color: over ? colors.accentText : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(over ? 'over' : 'left', style: context.text.caption),
          ],
        ),
        const SizedBox(width: Dimens.gapXs),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: AppMotion.expand,
          curve: AppMotion.expandCurve,
          child: Icon(
            Icons.expand_more_rounded,
            size: Dimens.iconSize,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// How spending compares with an even pace by today, and the status badge.
class _PaceRow extends StatelessWidget {
  const _PaceRow({required this.progress, required this.planned});

  final BudgetProgress progress;
  final double planned;

  String _pace() {
    final limit = progress.budget.limit;
    final spent = progress.spent;
    if (progress.status == BudgetStatus.notStarted) {
      return 'Nothing spent yet';
    }
    if (progress.isOverLimit) {
      return '${progress.percentRounded}% of the limit used';
    }
    final gap = spent - planned;
    if (gap.abs() < limit * 0.05) return 'On pace for today';
    return gap > 0
        ? '$currencyCode ${formatWhole(gap)} over plan so far'
        : '$currencyCode ${formatWhole(-gap)} under plan so far';
  }

  @override
  Widget build(BuildContext context) {
    final (tone, label) = switch (progress.status) {
      BudgetStatus.notStarted => (StatusTone.neutral, 'Not started'),
      BudgetStatus.onTrack => (StatusTone.success, 'On track'),
      BudgetStatus.nearLimit => (StatusTone.warning, 'Near limit'),
      BudgetStatus.overLimit => (StatusTone.danger, 'Over budget'),
    };
    return Row(
      children: [
        Expanded(
          child: Text(_pace(), style: context.text.caption, maxLines: 2),
        ),
        const SizedBox(width: Dimens.gapS),
        StatusBadge(tone: tone, label: label),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.dailyAllowance,
    required this.dailyAverage,
    required this.onEdit,
  });

  final double dailyAllowance;
  final double dailyAverage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimens.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Left per day',
                  value: formatZmw(dailyAllowance),
                  icon: Icons.today_outlined,
                ),
              ),
              const SizedBox(width: Dimens.gapM),
              Expanded(
                child: StatTile(
                  label: 'Spent per day',
                  value: formatZmw(dailyAverage),
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.gapS),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hold and drag to reorder',
                  style: context.text.caption,
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: Dimens.iconSizeSmall,
                ),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
