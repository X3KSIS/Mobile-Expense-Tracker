import 'package:flutter/material.dart';

import '../../../domain/models/app_user.dart';
import '../../../utils/phone.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/user_avatar.dart';

/// Navy feature card with the avatar, name, email and membership date.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.user, required this.memberSince});

  final AppUser user;
  final String memberSince;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = AppTypography.body.copyWith(
      color: AppColors.textOnNavyMuted,
    );
    final phone = user.phone;
    return Container(
      padding: const EdgeInsets.all(Dimens.cardPadding + 2),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          UserAvatar(initials: user.initials, large: true),
          const SizedBox(width: Dimens.gapL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.profileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimens.gapXs),
                Text(
                  user.email,
                  style: mutedStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(formatPhone(phone), style: mutedStyle),
                ],
                const SizedBox(height: Dimens.gapS + 2),
                Text(
                  memberSince.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textOnNavyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
