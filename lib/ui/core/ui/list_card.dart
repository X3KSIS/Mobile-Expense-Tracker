import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';

/// White rounded list container (radius 22, 1px border) with inset
/// dividers between [children].
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});

  final List<Widget> children;

  /// Lines up dividers with the text after a 44px icon tile.
  static const double dividerIndent =
      Dimens.gapL + Dimens.iconTileSize + Dimens.gapM;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusList);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: radius,
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.move,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      indent: dividerIndent,
                      endIndent: Dimens.gapL,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
