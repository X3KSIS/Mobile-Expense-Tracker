import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

/// Rounded-square avatar showing the user's initials on soft coral.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.large = false});

  final String initials;

  /// 72px with bigger initials (profile) instead of 48px (headers).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? Dimens.avatarSizeLarge : Dimens.avatarSize;
    final radius = large ? Dimens.radiusAvatarLarge : Dimens.radiusButton;
    final style = large
        ? AppTypography.avatarInitialsLarge
        : AppTypography.sectionTitle.copyWith(color: AppColors.accentText);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(initials, style: style),
    );
  }
}
