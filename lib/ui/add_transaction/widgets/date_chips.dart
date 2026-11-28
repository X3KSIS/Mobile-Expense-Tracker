import 'package:flutter/material.dart';

import '../../../utils/dates.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/choice_pill.dart';

/// "When": Today, Yesterday, or another date from the picker (the chip
/// then shows that date).
class DateChips extends StatelessWidget {
  const DateChips({
    super.key,
    required this.date,
    required this.daysAgo,
    required this.firstDate,
    required this.lastDate,
    required this.onDaysAgo,
    required this.onPicked,
  });

  final DateTime date;

  /// 0 for today, 1 for yesterday, null for another day.
  final int? daysAgo;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<int> onDaysAgo;
  final ValueChanged<DateTime> onPicked;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final other = daysAgo == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When', style: context.text.fieldLabel),
        const SizedBox(height: Dimens.gapS),
        Wrap(
          spacing: Dimens.gapS,
          runSpacing: Dimens.gapS,
          children: [
            ChoicePill(
              label: 'Today',
              selected: daysAgo == 0,
              onTap: () => onDaysAgo(0),
            ),
            ChoicePill(
              label: 'Yesterday',
              selected: daysAgo == 1,
              onTap: () => onDaysAgo(1),
            ),
            ChoicePill(
              icon: Icons.calendar_today_outlined,
              label: other
                  ? formatPickerDate(date, now: lastDate)
                  : 'Other date',
              selected: other,
              semanticLabel: other
                  ? '${formatPickerDate(date, now: lastDate)}. Change date'
                  : 'Pick another date',
              onTap: () => _pick(context),
            ),
          ],
        ),
      ],
    );
  }
}
