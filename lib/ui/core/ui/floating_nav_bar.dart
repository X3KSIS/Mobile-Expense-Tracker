import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';
import '../themes/theme.dart';

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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimens.radiusFull),
              border: Border.all(color: AppColors.navBorder),
              boxShadow: AppShadows.soft,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _NavItem(
                      destination: destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                ],
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          height: Dimens.navItemHeight,
          constraints: const BoxConstraints(minWidth: Dimens.minTouchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? Dimens.gapL : 11,
          ),
          decoration: ShapeDecoration(
            color: selected ? AppColors.surfaceMuted : AppColors.surface,
            shape: const StadiumBorder(),
          ),
          child: AnimatedSize(
            duration: _duration,
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(destination.icon, size: Dimens.iconSize, color: color),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Text(destination.label, style: AppTypography.navLabel),
                ],
              ],
            ),
          ),
        ),
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
      child: Container(
        width: Dimens.navFabSize,
        height: Dimens.navFabSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: AppColors.fab,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.add_rounded,
              size: 28,
              color: AppColors.onFab,
            ),
          ),
        ),
      ),
    );
  }
}
