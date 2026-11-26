import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/category_tile.dart';
import '../../core/ui/pressable.dart';

/// A full-width card leading to the complete history, e.g. "See all
/// activity · 54 transactions".
class SeeAllButton extends StatelessWidget {
  const SeeAllButton({super.key, required this.total, required this.onTap});

  /// Transactions in the full history.
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusList);
    return Semantics(
      button: true,
      label: 'See all activity, $total transactions',
      excludeSemantics: true,
      child: Pressable(
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(Dimens.gapL),
              child: Row(
                children: [
                  const IconTile(icon: Icons.history_rounded),
                  const SizedBox(width: Dimens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('See all activity', style: context.text.listTitle),
                        const SizedBox(height: 2),
                        Text(
                          '$total transaction${total == 1 ? '' : 's'}, '
                          'month by month',
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: Dimens.iconSize,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
