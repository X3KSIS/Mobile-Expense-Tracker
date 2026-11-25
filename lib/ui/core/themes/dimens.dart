import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Spacing, size and radius tokens (see CLAUDE.md).
abstract final class Dimens {
  // Spacing
  static const double screenPadding = 22;
  static const double sectionGap = 18;
  static const double gapXs = 4;
  static const double gapS = 8;
  static const double gapM = 12;
  static const double gapL = 16;
  static const double cardPadding = 20;

  // Radii
  static const double radiusCard = 26;
  static const double radiusList = 22;
  static const double radiusButton = 16;
  static const double radiusInput = 14;
  static const double radiusIconTile = 14;
  static const double radiusTile = 18;
  static const double radiusAvatarLarge = 22;
  static const double radiusDialog = 24;
  static const double radiusFull = 999;

  // Component sizes
  static const double minTouchTarget = 44;
  static const double avatarSize = 48;
  static const double avatarSizeLarge = 72;
  static const double authLogoSize = 64;
  static const double headerButtonSize = 46;
  static const double iconTileSize = 44;
  static const double quickActionSize = 52;
  static const double buttonHeight = 48;
  static const double primaryButtonHeight = 58;
  static const double iconSize = 22;
  static const double iconSizeSmall = 18;
  static const double notificationDotSize = 9;
  static const double buttonSpinnerSize = 22;
  static const double menuRowMinHeight = 60;
  static const double progressBarHeight = 8;
  static const double emptyStateTileSize = 64;
  static const double emptyStateIconSize = 28;

  // Charts
  static const double chartHeight = 150;
  static const double columnMaxWidth = 24;
  static const double dataEndRadius = 4;
  static const double heatCellGap = 4;
  static const double meterHeight = 8;

  // Bottom navigation
  static const double navBarHeight = 64;
  static const double navBarMargin = 18;
  static const double navFabSize = 64;
  static const double navItemHeight = 46;

  /// Bottom padding scrollable screens inside the shell need so their last
  /// item can scroll above the floating nav bar.
  static double navBarClearance(BuildContext context) =>
      navBarHeight +
      navBarMargin +
      sectionGap +
      MediaQuery.viewPaddingOf(context).bottom;
}

/// Soft shadows. Gradients live in `gradients.dart`.
abstract final class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Soft coral glow under the primary action button.
  static const List<BoxShadow> coral = [
    BoxShadow(
      color: AppColors.accentShadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
