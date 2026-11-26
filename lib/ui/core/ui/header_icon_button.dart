import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'pressable.dart';

/// 46px rounded-square icon button on the surface colour with a 1px
/// border, used in screen headers. Optionally shows a coral notification
/// dot. Shrinks slightly and springs back when pressed.
///
/// Pass an [icon], or a custom [child] such as an animated icon.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    this.icon,
    this.child,
    required this.tooltip,
    required this.onPressed,
    this.showBadge = false,
  }) : assert(
         (icon == null) != (child == null),
         'Pass either an icon or a child',
       );

  final IconData? icon;

  /// Shown instead of [icon], centred in the button.
  final Widget? child;

  /// Also used as the accessibility label.
  final String tooltip;
  final VoidCallback onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusButton);
    return Tooltip(
      message: tooltip,
      child: Pressable(
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox.square(
              dimension: Dimens.headerButtonSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child ??
                      Icon(
                        icon,
                        size: Dimens.iconSize,
                        color: colors.textPrimary,
                      ),
                  if (showBadge)
                    Positioned(
                      top: 12,
                      right: 13,
                      child: Container(
                        width: Dimens.notificationDotSize,
                        height: Dimens.notificationDotSize,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                      ),
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
