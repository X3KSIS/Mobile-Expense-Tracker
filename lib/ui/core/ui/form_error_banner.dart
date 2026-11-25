import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

/// Soft coral banner for a form-level error, e.g. a failed sign-in.
/// Announced to screen readers as a live region.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimens.gapM + 2),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(Dimens.radiusInput),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: Dimens.iconSizeSmall + 2,
              color: AppColors.accentText,
            ),
            const SizedBox(width: Dimens.gapS + 2),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.accentText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
