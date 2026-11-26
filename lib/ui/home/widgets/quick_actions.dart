import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/pressable.dart';

/// Shortcuts shown on the Home screen.
enum QuickAction {
  expense('Expense', Icons.north_east_rounded),
  income('Income', Icons.south_west_rounded),
  receipt('Receipt', Icons.receipt_long_outlined),
  grocery('Grocery', Icons.shopping_basket_outlined);

  const QuickAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Four equal columns of quick action buttons.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.onSelected});

  final ValueChanged<QuickAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final action in QuickAction.values)
          Expanded(
            child: _QuickActionButton(
              action: action,
              onPressed: () => onSelected(action),
            ),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, required this.onPressed});

  final QuickAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusButton);
    final labelStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.colors.textPrimary);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: Pressable(
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.gapXs),
            child: Column(
              children: [
                Container(
                  width: Dimens.quickActionSize,
                  height: Dimens.quickActionSize,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: radius,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Icon(
                    action.icon,
                    size: Dimens.iconSize,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.gapS),
                Text(action.label, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
