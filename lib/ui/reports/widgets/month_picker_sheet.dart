import 'package:flutter/material.dart';

import '../../../utils/currency.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/pressable.dart';

/// Lets the user jump straight to any month from [first] to [last]: a year
/// switcher over a grid of the twelve months, each with what was spent in
/// it. Resolves to the chosen month, or null when dismissed.
Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required DateTime selected,
  required DateTime first,
  required DateTime last,
  required double Function(DateTime month) spentIn,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _MonthPicker(
      selected: selected,
      first: first,
      last: last,
      spentIn: spentIn,
    ),
  );
}

class _MonthPicker extends StatefulWidget {
  const _MonthPicker({
    required this.selected,
    required this.first,
    required this.last,
    required this.spentIn,
  });

  final DateTime selected;
  final DateTime first;
  final DateTime last;
  final double Function(DateTime month) spentIn;

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year = widget.selected.year;

  bool _allowed(DateTime month) =>
      !month.isBefore(widget.first) && !month.isAfter(widget.last);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Dimens.screenPadding,
          0,
          Dimens.screenPadding,
          Dimens.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose a month', style: context.text.sectionTitle),
            const SizedBox(height: Dimens.gapL),
            _YearSwitcher(
              year: _year,
              onBack: _year > widget.first.year
                  ? () => setState(() => _year--)
                  : null,
              onForward: _year < widget.last.year
                  ? () => setState(() => _year++)
                  : null,
            ),
            const SizedBox(height: Dimens.gapL),
            FadeSwitcher(
              child: GridView.count(
                key: ValueKey(_year),
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Dimens.gapS,
                crossAxisSpacing: Dimens.gapS,
                childAspectRatio: 1.6,
                children: [
                  for (var m = 1; m <= 12; m++)
                    _MonthCell(
                      month: DateTime(_year, m),
                      selected: DateTime(_year, m) == widget.selected,
                      spent: _allowed(DateTime(_year, m))
                          ? widget.spentIn(DateTime(_year, m))
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(DateTime(_year, m)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({
    required this.year,
    required this.onBack,
    required this.onForward,
  });

  final int year;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous year',
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: FadeSwitcher(
              alignment: Alignment.center,
              child: Text(
                '$year',
                key: ValueKey(year),
                style: context.text.listTitle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next year',
          onPressed: onForward,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// One month: its short name and what was spent, navy when selected.
/// [spent] is null for months outside the range, which can't be picked.
class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.selected,
    required this.spent,
    required this.onTap,
  });

  final DateTime month;
  final bool selected;
  final double? spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spent = this.spent;
    final enabled = spent != null;
    final foreground = selected
        ? colors.textOnNavy
        : enabled
        ? colors.textPrimary
        : colors.textSecondary;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: enabled
          ? '${formatMonthYear(month)}, spent ${formatZmw(spent)}'
          : '${formatMonthYear(month)}, no data',
      excludeSemantics: true,
      child: Pressable(
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(Dimens.radiusInput),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.move,
              decoration: BoxDecoration(
                color: selected ? colors.navy : colors.surface,
                borderRadius: BorderRadius.circular(Dimens.radiusInput),
                border: Border.all(
                  color: selected ? colors.navy : colors.border,
                ),
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatMonthShort(month),
                      style: context.text.listTitle.copyWith(color: foreground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? '$currencyCode ${formatCompact(spent)}' : '–',
                      style: context.text.caption.copyWith(
                        color: selected ? colors.textOnNavyMuted : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
