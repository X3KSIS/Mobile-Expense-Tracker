import 'package:flutter/material.dart';

import '../../../domain/models/app_user.dart';
import '../../../domain/models/tracking_stats.dart';
import '../../../utils/phone.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/gradients.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/animated_number.dart';
import '../../core/ui/mesh_gradient_box.dart';
import '../../core/ui/pressable.dart';
import '../../core/ui/user_avatar.dart';

/// Navy feature card: avatar, name, @username, email and phone, then how
/// steadily the user records their money (day streak, this month, months
/// tracked) and the membership date. Tap it to edit personal details.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    required this.stats,
    required this.memberSince,
    required this.onTap,
  });

  final AppUser user;
  final TrackingStats stats;
  final String memberSince;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusCard);
    return Semantics(
      button: true,
      hint: 'Edit personal details',
      child: Pressable(
        child: MeshGradientBox(
          mesh: context.gradients.navyMesh,
          borderRadius: radius,
          boxShadow: context.shadows.soft,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.all(Dimens.cardPadding + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Identity(user: user),
                    const SizedBox(height: Dimens.gapL),
                    Divider(color: context.colors.navyTrack, height: 1),
                    const SizedBox(height: Dimens.gapL),
                    _Stats(stats: stats),
                    const SizedBox(height: Dimens.gapL),
                    Text(
                      memberSince.toUpperCase(),
                      style: context.text.overline.copyWith(
                        color: context.colors.textOnNavyMuted,
                      ),
                    ),
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

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.body.copyWith(
      color: context.colors.textOnNavyMuted,
    );
    final username = user.username;
    final phone = user.phone;
    return Row(
      children: [
        UserAvatar(initials: user.initials, photo: user.photo, large: true),
        const SizedBox(width: Dimens.gapL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: context.text.profileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (username != null) ...[
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: context.text.label.copyWith(
                    color: context.colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: Dimens.gapXs),
              Text(
                user.email,
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (phone != null) Text(formatPhone(phone), style: muted),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: context.colors.textOnNavyMuted,
        ),
      ],
    );
  }
}

/// Three equal columns: day streak, recorded this month, months tracked.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final TrackingStats stats;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(value: stats.streak, label: 'Day streak'),
          ),
          VerticalDivider(color: context.colors.navyTrack, width: 1),
          Expanded(
            child: _Stat(value: stats.thisMonth, label: 'This month'),
          ),
          VerticalDivider(color: context.colors.navyTrack, width: 1),
          Expanded(
            child: _Stat(
              value: stats.monthsTracked,
              label: stats.monthsTracked == 1
                  ? 'Month tracked'
                  : 'Months tracked',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        children: [
          AnimatedNumber(
            value: value.toDouble(),
            builder: (context, shown) => Text(
              '${shown.round()}',
              style: context.text.statValue.copyWith(
                color: context.colors.accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.caption.copyWith(
              color: context.colors.textOnNavyMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
