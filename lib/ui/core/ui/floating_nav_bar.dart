import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/motion.dart';
import '../themes/theme.dart';
import 'pressable.dart';

/// One tab in the [FloatingNavBar].
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// White floating pill with the tabs, plus the black circular "+" button.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: Dimens.navBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: Dimens.gapS),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(Dimens.radiusFull),
              border: Border.all(color: context.colors.navBorder),
              boxShadow: context.shadows.soft,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxLabelWidth = _NavItem.labelWidthLimit(
                    constraints.maxWidth,
                    destinations.length,
                  );
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        _NavItem(
                          destination: destinations[i],
                          selected: i == currentIndex,
                          maxLabelWidth: maxLabelWidth,
                          onTap: () => onDestinationSelected(i),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimens.gapM),
        _AddButton(onPressed: onAddPressed),
      ],
    );
  }
}

/// A tab that smoothly grows into a labelled pill when selected.
///
/// One animated value (0 = inactive, 1 = active) drives everything: the
/// pill colour, padding and icon colour blend, the label slides open, and
/// it fades in once there is room. The old and new tabs animate together,
/// so the bar's total width stays within bounds throughout.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.maxLabelWidth,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final double maxLabelWidth;
  final VoidCallback onTap;

  static const double _paddingInactive = 11;
  static const double _paddingActive = 14;
  static const double _labelGap = 6;

  /// The widest a label may be so the active pill plus the inactive icons
  /// fit in [available] width. Long labels ellipsize past this.
  static double labelWidthLimit(double available, int count) {
    const inactive = Dimens.minTouchTarget;
    const activeChrome = _paddingActive * 2 + Dimens.iconSize + _labelGap;
    final width = available - (count - 1) * inactive - activeChrome;
    return width < 0 ? 0 : width;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: AppMotion.long,
          curve: AppMotion.move,
          builder: (context, t, _) => _buildPill(context, t),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, double t) {
    final iconColor = Color.lerp(
      context.colors.textSecondary,
      context.colors.textPrimary,
      t,
    );
    // The label fades in during the second half, once the pill has opened.
    final labelOpacity = Curves.easeIn.transform(
      ((t - 0.35) / 0.65).clamp(0.0, 1.0),
    );
    return Container(
      height: Dimens.navItemHeight,
      constraints: const BoxConstraints(minWidth: Dimens.minTouchTarget),
      padding: EdgeInsets.symmetric(
        horizontal: lerpDouble(_paddingInactive, _paddingActive, t)!,
      ),
      decoration: ShapeDecoration(
        color: Color.lerp(
          context.colors.surface,
          context.colors.surfaceMuted,
          t,
        ),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(destination.icon, size: Dimens.iconSize, color: iconColor),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: t,
              child: Opacity(
                opacity: labelOpacity,
                child: Padding(
                  padding: const EdgeInsets.only(left: _labelGap),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Text(
                      destination.label,
                      style: context.text.navLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add transaction',
      child: Pressable(
        child: Container(
          width: Dimens.navFabSize,
          height: Dimens.navFabSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: context.shadows.soft,
          ),
          child: Material(
            color: context.colors.fab,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: context.colors.onFab,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
