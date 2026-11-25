import 'package:flutter/painting.dart';

/// Colour tokens from the coral and navy design system (see CLAUDE.md).
abstract final class AppColors {
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEEEEF1);
  static const Color surfaceMuted = Color(0xFFF1F1F3);
  static const Color navy = Color(0xFF1B2A38);
  static const Color textPrimary = Color(0xFF1B2433);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnNavyMuted = Color(0xFFB8C2CC);

  /// Highlights, big numbers on navy, progress, decoration.
  /// Never for small text or behind white text.
  static const Color accent = Color(0xFFFF6B4A);

  /// Primary buttons (white text passes contrast).
  static const Color accentStrong = Color(0xFFD2401F);

  /// Coral text and links on light backgrounds.
  static const Color accentText = Color(0xFFC2391A);
  static const Color accentSoft = Color(0xFFFFE6DF);
  static const Color success = Color(0xFF177A4B);
  static const Color successSoft = Color(0xFFE4F4EB);
  static const Color error = Color(0xFFB3261E);
  static const Color fab = Color(0xFF141A22);
  static const Color onFab = Color(0xFFFFFFFF);

  /// Progress track on navy cards: white at 12 % opacity.
  static const Color navyTrack = Color(0x1FFFFFFF);

  /// Highlight band that sweeps across skeleton placeholders.
  static const Color skeletonHighlight = Color(0xFFFAFAFB);

  // Charts
  /// De-emphasised marks (the months that are not selected).
  static const Color chartMuted = Color(0xFFD5D9E0);

  /// Hairline gridlines.
  static const Color chartGrid = Color(0xFFEEEEF1);

  /// Sequential coral ramp for the spending heatmap, lightest to darkest.
  /// Step 0 is a day with no spending. Steps 0–3 take dark text, step 4
  /// takes white text.
  static const List<Color> heatRamp = [
    surfaceMuted,
    Color(0xFFFFE6DF),
    Color(0xFFFFC2B2),
    Color(0xFFFF9478),
    accentStrong,
  ];

  /// 1px border of the floating bottom nav pill.
  static const Color navBorder = Color(0xFFECECEF);

  /// textPrimary at 8 % opacity, for soft shadows.
  static const Color shadow = Color(0x141B2433);

  /// accentStrong at 28 % opacity, for the primary button's coral shadow.
  static const Color accentShadow = Color(0x47D2401F);

  /// Opacity used for soft category tiles and decorative shapes.
  static const double softTintAlpha = 0.12;
}
