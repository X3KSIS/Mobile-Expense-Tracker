import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// 46px white rounded-square icon button with a 1px border, used in screen
/// headers. Optionally shows a coral notification dot.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showBadge = false,
  });

  final IconData icon;

  /// Also used as the accessibility label.
  final String tooltip;
  final VoidCallback onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusButton);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: Dimens.headerButtonSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: Dimens.iconSize, color: AppColors.textPrimary),
                if (showBadge)
                  Positioned(
                    top: 12,
                    right: 13,
                    child: Container(
                      width: Dimens.notificationDotSize,
                      height: Dimens.notificationDotSize,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
