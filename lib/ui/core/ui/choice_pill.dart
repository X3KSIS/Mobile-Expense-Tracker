import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'pressable.dart';

/// A rounded chip in the wallet-chip style: white with a border, or navy
/// when [selected]. Optional leading [icon] and a muted [detail] after
/// the label, e.g. an amount.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.detail,
    this.selected = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? detail;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.textOnNavy : colors.textPrimary;
    final muted = selected ? colors.textOnNavyMuted : colors.textSecondary;
    final radius = BorderRadius.circular(Dimens.radiusInput);
    final icon = this.icon;
    final detail = this.detail;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? [label, ?detail].join(', '),
      excludeSemantics: true,
      child: Pressable(
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.move,
          constraints: const BoxConstraints(minHeight: Dimens.minTouchTarget),
          decoration: BoxDecoration(
            color: selected ? colors.navy : colors.surface,
            borderRadius: radius,
            border: Border.all(color: selected ? colors.navy : colors.border),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.gapM,
                  vertical: Dimens.gapS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: Dimens.iconSizeSmall,
                        color: selected ? foreground : colors.accentText,
                      ),
                      const SizedBox(width: Dimens.gapS),
                    ],
                    Text(
                      label,
                      style: context.text.button.copyWith(color: foreground),
                    ),
                    if (detail != null) ...[
                      const SizedBox(width: Dimens.gapS),
                      Text(
                        detail,
                        style: context.text.caption.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
