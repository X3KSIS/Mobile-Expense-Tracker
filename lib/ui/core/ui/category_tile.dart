import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'category_icon.dart';

/// 44px rounded tile with a category's outline icon on a soft tint of its
/// colour. The colour is nudged lighter on dark surfaces (or darker on
/// light ones) until the icon keeps 3:1 contrast, so a navy category stays
/// visible in dark mode.
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
    final tint = legibleOn(Color(color), context.colors.surface);
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

/// [color] adjusted in lightness, keeping its hue, until it has at least
/// [minContrast] against [surface].
Color legibleOn(Color color, Color surface, {double minContrast = 3}) {
  final surfaceLum = surface.computeLuminance();
  double contrast(Color c) {
    final l = c.computeLuminance();
    final hi = l > surfaceLum ? l : surfaceLum;
    final lo = l > surfaceLum ? surfaceLum : l;
    return (hi + 0.05) / (lo + 0.05);
  }

  final lighten = surfaceLum < 0.2;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 20 && contrast(hsl.toColor()) < minContrast; i++) {
    final next = hsl.lightness + (lighten ? 0.04 : -0.04);
    hsl = hsl.withLightness(next.clamp(0.0, 1.0));
  }
  return hsl.toColor();
}
