import 'package:flutter/material.dart';

import '../../../domain/models/pay_cycle.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'pressable.dart';
import 'primary_button.dart';

/// Asks which day of the month pay arrives. Resolves to the chosen day,
/// or null when dismissed.
Future<int?> showPaydayPicker(BuildContext context, {required int current}) {
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _PaydayPicker(initial: current),
  );
}

class _PaydayPicker extends StatefulWidget {
  const _PaydayPicker({required this.initial});

  final int initial;

  @override
  State<_PaydayPicker> createState() => _PaydayPickerState();
}

class _PaydayPickerState extends State<_PaydayPicker> {
  late int _day = widget.initial;

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
            Text('When do you get paid?', style: context.text.sectionTitle),
            const SizedBox(height: Dimens.gapXs),
            Text(
              'Budgets and your daily spending run from one payday to the '
              'next. Pick 1 for calendar months.',
              style: context.text.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: Dimens.gapL),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Dimens.gapS,
              crossAxisSpacing: Dimens.gapS,
              children: [
                for (var d = 1; d <= PayCycle.maxPayday; d++)
                  _DayCell(
                    day: d,
                    selected: d == _day,
                    onTap: () => setState(() => _day = d),
                  ),
              ],
            ),
            const SizedBox(height: Dimens.sectionGap + 4),
            PrimaryButton(
              label: 'Save payday',
              onPressed: () => Navigator.of(context).pop(_day),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusInput);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Day $day',
      excludeSemantics: true,
      child: Pressable(
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.move,
          decoration: BoxDecoration(
            color: selected ? colors.navy : colors.surface,
            borderRadius: radius,
            border: Border.all(color: selected ? colors.navy : colors.border),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Center(
                child: Text(
                  '$day',
                  style: context.text.button.copyWith(
                    color: selected ? colors.textOnNavy : colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
