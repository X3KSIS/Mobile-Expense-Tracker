import 'package:flutter/material.dart';

import '../../../domain/models/budget_progress.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/expandable_section.dart';
import '../../core/ui/progress_bar.dart';
import '../../core/ui/stat_tile.dart';
import '../../core/ui/status_badge.dart';

/// One budget: category, amount spent of the limit, a progress bar, how
/// much is left (or over) and a status badge.
///
/// Tapping the card expands it (350 ms, ease out) to show the daily
/// allowance, the daily average and an edit button.
class BudgetCard extends StatefulWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    required this.dailyAllowance,
    required this.dailyAverage,
    required this.onEdit,
  });

  final BudgetProgress progress;

  /// What can still be spent each day for the rest of the month.
  final double dailyAllowance;

  /// Average spent per day so far this month.
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
                ProgressBar(
                  value: progress.percentUsed,
                  color: progress.needsAttention
                      ? colors.accentStrong
                      : colors.accent,
                  semanticLabel: '${progress.budget.categoryName} budget used',
                ),
                const SizedBox(height: Dimens.gapM),
                _StatusRow(progress: progress),
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

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.expanded});

  final BudgetProgress progress;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final budget = progress.budget;
    return Row(
      children: [
        CategoryTile(icon: budget.categoryIcon),
        const SizedBox(width: Dimens.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(budget.categoryName, style: context.text.listTitle),
              const SizedBox(height: 2),
              Text(
                '${formatZmw(progress.spent)} of ${formatZmw(budget.limit)}',
                style: context.text.caption,
              ),
            ],
          ),
        ),
        Text(
          '${progress.percentRounded}%',
          style: context.text.statValue.copyWith(
            color: progress.needsAttention
                ? colors.accentText
                : colors.textPrimary,
          ),
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

/// "ZMW 100.00 left" and the status badge.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final over = progress.isOverLimit;
    final (tone, label) = switch (progress.status) {
      BudgetStatus.notStarted => (StatusTone.neutral, 'Not started'),
      BudgetStatus.onTrack => (StatusTone.success, 'On track'),
      BudgetStatus.nearLimit => (StatusTone.warning, 'Near limit'),
      BudgetStatus.overLimit => (StatusTone.danger, 'Over budget'),
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            over
                ? '${formatZmw(progress.overBy)} over'
                : '${formatZmw(progress.remaining)} left',
            style: context.text.caption.copyWith(
              color: over ? colors.accentText : colors.textSecondary,
              fontWeight: over ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
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
