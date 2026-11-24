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

  /// 1px border of the floating bottom nav pill.
  static const Color navBorder = Color(0xFFECECEF);

  /// textPrimary at 8 % opacity, for soft shadows.
  static const Color shadow = Color(0x141B2433);

  /// Opacity used for soft category tiles and decorative shapes.
  static const double softTintAlpha = 0.12;
}
