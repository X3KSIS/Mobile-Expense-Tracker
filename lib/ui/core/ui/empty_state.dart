import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// Centered icon, title, message and an optional action, for empty lists
/// and load errors.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.screenPadding,
        vertical: Dimens.sectionGap * 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(Dimens.radiusTile),
            ),
            child: Icon(icon, size: 28, color: AppColors.accentText),
          ),
          const SizedBox(height: Dimens.gapL),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.gapXs),
          Text(
            message,
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (label != null) ...[
            const SizedBox(height: Dimens.gapL),
            OutlinedButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
