import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'category_icon.dart';

/// 44px rounded tile with a category's outline icon on a soft tint of its
/// colour.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = Dimens.iconTileSize,
  });

  /// Icon key, resolved by [CategoryIcons].
  final String icon;

  /// ARGB colour value.
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = Color(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: context.colors.softTintAlpha),
        borderRadius: BorderRadius.circular(Dimens.radiusIconTile),
      ),
      child: Icon(
        CategoryIcons.resolve(icon),
        size: Dimens.iconSize,
        color: tint,
      ),
    );
  }
}
