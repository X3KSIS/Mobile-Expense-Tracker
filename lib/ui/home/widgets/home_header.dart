import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/header_icon_button.dart';

/// Avatar, greeting and the notifications bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.initials,
    required this.onNotificationsPressed,
    this.hasUnreadNotifications = true,
  });

  final String userName;
  final String initials;
  final VoidCallback onNotificationsPressed;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        _Avatar(initials: initials),
        const SizedBox(width: Dimens.gapM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                userName,
                style: textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          showBadge: hasUnreadNotifications,
          onPressed: onNotificationsPressed,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.avatarSize,
      height: Dimens.avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(Dimens.radiusButton),
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.accentText),
      ),
    );
  }
}
