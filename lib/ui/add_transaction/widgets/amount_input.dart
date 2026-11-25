import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';

/// Big amount entry: a white card with a grey "ZMW" prefix and the number
/// in the large amount style.
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.validator,
    required this.label,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  /// Overline above the field, e.g. "EXPENSE AMOUNT".
  final String label;
  final bool autofocus;

  /// Digits with an optional point and up to two decimals.
  static final RegExp _amountPattern = RegExp(r'^\d*\.?\d{0,2}');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimens.cardPadding,
        Dimens.gapL,
        Dimens.cardPadding,
        Dimens.gapS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSwitcher(
            alignment: Alignment.centerLeft,
            duration: AppMotion.short,
            child: Text(
              label.toUpperCase(),
              key: ValueKey(label),
              style: AppTypography.overline,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(currencyCode, style: AppTypography.amountPrefix),
              const SizedBox(width: Dimens.gapS),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  autofocus: autofocus,
                  style: AppTypography.amountLarge,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(_amountPattern),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTypography.amountLarge.copyWith(
                      color: AppColors.border,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Dimens.gapS,
                    ),
                    errorStyle: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
