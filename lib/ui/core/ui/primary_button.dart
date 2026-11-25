import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

/// Full-width, fully rounded accentStrong button (height 58) with a soft
/// coral shadow. Shows a spinner and ignores taps while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: loading ? '$label, in progress' : label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimens.radiusFull),
          boxShadow: enabled ? AppShadows.coral : null,
        ),
        child: FilledButton(
          onPressed: loading ? () {} : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Dimens.primaryButtonHeight),
            shape: const StadiumBorder(),
            textStyle: AppTypography.primaryButton,
          ),
          child: loading
              ? const SizedBox.square(
                  dimension: Dimens.buttonSpinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.surface,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
