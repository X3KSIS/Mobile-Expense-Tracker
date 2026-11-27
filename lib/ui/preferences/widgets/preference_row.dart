import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// Title and explanation, with an optional control on the right and an
/// optional one underneath (e.g. a segmented choice).
class PreferenceRow extends StatelessWidget {
  const PreferenceRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final below = this.below;
    final row = InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dimens.menuRowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gapL,
            vertical: Dimens.gapM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.listTitle),
                        const SizedBox(height: 2),
                        Text(subtitle, style: context.text.caption),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: Dimens.gapS),
                    trailing!,
                  ],
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(left: Dimens.gapXs),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: Dimens.iconSize,
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
              if (below != null) ...[
                const SizedBox(height: Dimens.gapM),
                below,
              ],
            ],
          ),
        ),
      ),
    );
    // A row with a switch reads as one control; rows with choices below
    // keep each choice separate.
    return below == null ? MergeSemantics(child: row) : row;
  }
}
