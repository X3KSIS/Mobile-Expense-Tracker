import 'package:flutter/material.dart';

import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// Labelled, input-styled button that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.label = 'Date',
  });

  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusInput);
    final value = formatPickerDate(date, now: lastDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.fieldLabel),
        const SizedBox(height: Dimens.gapS),
        Semantics(
          button: true,
          label: '$label, $value. Change date',
          excludeSemantics: true,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => _pick(context),
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapL - 4,
                  vertical: Dimens.gapL,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: Dimens.iconSizeSmall + 2,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: Dimens.gapM),
                    Expanded(child: Text(value, style: AppTypography.body)),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: Dimens.iconSize,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
