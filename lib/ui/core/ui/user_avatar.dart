import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';

/// The user's photo in a rounded square, or their initials on soft coral
/// when there is no photo. Swapping between them cross-fades.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.photo,
    this.large = false,
  });

  final String initials;

  /// JPEG bytes of the profile photo, or null.
  final Uint8List? photo;

  /// 72px with bigger initials (profile) instead of 48px (headers).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? Dimens.avatarSizeLarge : Dimens.avatarSize;
    final radius = BorderRadius.circular(
      large ? Dimens.radiusAvatarLarge : Dimens.radiusButton,
    );
    final style = large
        ? context.text.avatarInitialsLarge
        : context.text.sectionTitle.copyWith(color: context.colors.accentText);
    final photo = this.photo;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: photo == null
            ? Container(
                key: const ValueKey('initials'),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.accentSoft,
                  borderRadius: radius,
                ),
                child: Text(initials, style: style),
              )
            : ClipRRect(
                key: ValueKey(photo.length),
                borderRadius: radius,
                child: Image.memory(
                  photo,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  semanticLabel: 'Profile photo',
                ),
              ),
      ),
    );
  }
}
