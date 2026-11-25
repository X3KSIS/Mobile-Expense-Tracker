import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

/// Muted tile with a small icon, a caption and a bold value.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Dimens.gapM + 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(Dimens.radiusTile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: Dimens.iconSizeSmall, color: valueColor),
                const SizedBox(width: Dimens.gapXs + 2),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.gapS - 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.statValue.copyWith(color: valueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
