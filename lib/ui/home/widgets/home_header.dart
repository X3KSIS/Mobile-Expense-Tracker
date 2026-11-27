import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/sun_moon_icon.dart';
import '../../core/ui/user_avatar.dart';

/// Avatar, greeting, the light/dark theme toggle and the notifications
/// bell. Tapping the avatar or the
/// name opens the profile.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.initials,
    this.photo,
    required this.onProfilePressed,
    required this.onNotificationsPressed,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.hasUnreadNotifications = true,
  });

  final String userName;
  final String initials;
  final Uint8List? photo;
  final VoidCallback onProfilePressed;
  final VoidCallback onNotificationsPressed;
  final bool hasUnreadNotifications;

  /// Whether the dark theme is showing; the toggle shows a moon when true.
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: 'Profile',
            child: Semantics(
              button: true,
              label: 'Profile, $userName',
              excludeSemantics: true,
              child: InkWell(
                onTap: onProfilePressed,
                borderRadius: BorderRadius.circular(Dimens.radiusButton),
                child: Row(
                  children: [
                    UserAvatar(initials: initials, photo: photo),
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
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimens.gapM),
        HeaderIconButton(
          tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () => onDarkModeChanged(!isDarkMode),
          child: SunMoonIcon(isMoon: isDarkMode),
        ),
        const SizedBox(width: Dimens.gapS),
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
