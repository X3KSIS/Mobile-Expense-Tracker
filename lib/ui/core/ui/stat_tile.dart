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
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Defaults to the primary text colour.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final valueColor = this.valueColor ?? context.colors.textPrimary;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Dimens.gapM + 2),
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
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
                    style: context.text.caption,
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
                style: context.text.statValue.copyWith(color: valueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
