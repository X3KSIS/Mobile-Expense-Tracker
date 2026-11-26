import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import 'category_icon.dart';

/// 44px rounded tile with a category's outline icon.
///
/// Every category uses the same coral tint (see "Icon tiles" in CLAUDE.md);
/// the icon tells categories apart. [emphasized] fills the tile with the
/// strong coral, e.g. for the selected category in a picker.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    this.size = Dimens.iconTileSize,
    this.emphasized = false,
  });

  /// Icon key, resolved by [CategoryIcons].
  final String icon;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return IconTile(
      icon: CategoryIcons.resolve(icon),
      size: size,
      emphasized: emphasized,
    );
  }
}

/// The shared icon tile: a coral outline icon on a soft coral square, or
/// white on strong coral when [emphasized]. Changes animate.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = Dimens.iconTileSize,
    this.emphasized = false,
  });

  final IconData icon;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.move,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: emphasized ? colors.accentStrong : colors.accentSoft,
        borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
      ),
      child: Icon(
        icon,
        size: Dimens.iconSize,
        color: emphasized ? colors.onAccentStrong : colors.accentText,
      ),
    );
  }
}
