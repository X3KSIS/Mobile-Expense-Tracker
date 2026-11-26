import 'package:flutter/material.dart';

/// Colour tokens from the coral and navy design system (see CLAUDE.md), in
/// a light and a dark palette.
///
/// Widgets read the active palette with `context.colors`. The palette is a
/// [ThemeExtension], so switching between light and dark blends every
/// colour smoothly while the theme animates.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.surfaceMuted,
    required this.navy,
    required this.navyMeshEnd,
    required this.navyGlowTop,
    required this.navyGlowBottom,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnNavy,
    required this.textOnNavyMuted,
    required this.accent,
    required this.accentStrong,
    required this.onAccentStrong,
    required this.accentText,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.neutral,
    required this.neutralSoft,
    required this.fab,
    required this.onFab,
    required this.navyTrack,
    required this.skeletonHighlight,
    required this.chartMuted,
    required this.chartGrid,
    required this.heatRamp,
    required this.navBorder,
    required this.shadow,
    required this.accentShadow,
    required this.primaryGradientEnd,
    required this.headlineGradientEnd,
  });

  /// Scaffold.
  final Color background;

  /// Cards.
  final Color surface;

  /// Card and button borders (1px).
  final Color border;

  /// Stat tiles, active nav pill, track backgrounds.
  final Color surfaceMuted;

  /// Feature cards, selected chips, segmented controls.
  final Color navy;

  /// Second stop and glows of the navy mesh gradient.
  final Color navyMeshEnd;
  final Color navyGlowTop;
  final Color navyGlowBottom;

  final Color textPrimary;
  final Color textSecondary;
  final Color textOnNavy;
  final Color textOnNavyMuted;

  /// Highlights, big numbers on navy, progress, decoration.
  /// Never for small text or behind white text.
  final Color accent;

  /// Primary buttons; [onAccentStrong] text on it passes contrast.
  final Color accentStrong;
  final Color onAccentStrong;

  /// Coral text and links on the background and surfaces.
  final Color accentText;
  final Color accentSoft;

  // Status colours. Each pairs a strong colour (icons, text) with a soft
  // background it passes 4.5:1 contrast on.

  /// Success / active / paid, and income amounts.
  final Color success;
  final Color successSoft;

  /// Warning / pending.
  final Color warning;
  final Color warningSoft;

  /// Failed / danger, and form errors.
  final Color error;
  final Color errorSoft;

  /// Draft / neutral.
  final Color neutral;
  final Color neutralSoft;

  /// The "+" button in the nav bar and the icon on it.
  final Color fab;
  final Color onFab;

  /// Progress track on navy cards.
  final Color navyTrack;

  /// Highlight band that sweeps across skeleton placeholders.
  final Color skeletonHighlight;

  /// De-emphasised chart marks (the months that are not selected).
  final Color chartMuted;

  /// Hairline gridlines.
  final Color chartGrid;

  /// Sequential coral ramp for the spending heatmap, lightest to most
  /// intense. Step 0 is a day with no spending. In the light palette steps
  /// 0–3 take dark text and step 4 white; in the dark palette every step
  /// takes light text.
  final List<Color> heatRamp;

  /// 1px border of the floating bottom nav pill.
  final Color navBorder;

  /// Soft shadows.
  final Color shadow;

  /// The primary button's coral shadow.
  final Color accentShadow;

  /// Second stops of the primary button and headline gradients.
  final Color primaryGradientEnd;
  final Color headlineGradientEnd;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF7F7F8),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFEEEEF1),
    surfaceMuted: Color(0xFFF1F1F3),
    navy: Color(0xFF1B2A38),
    navyMeshEnd: Color(0xFF1C3550),
    navyGlowTop: Color(0xCC2A3F66),
    navyGlowBottom: Color(0x99173B4A),
    textPrimary: Color(0xFF1B2433),
    textSecondary: Color(0xFF6B7280),
    textOnNavy: Color(0xFFFFFFFF),
    textOnNavyMuted: Color(0xFFB8C2CC),
    accent: Color(0xFFFF6B4A),
    accentStrong: Color(0xFFD2401F),
    onAccentStrong: Color(0xFFFFFFFF),
    accentText: Color(0xFFC2391A),
    accentSoft: Color(0xFFFFE6DF),
    success: Color(0xFF177A4B),
    successSoft: Color(0xFFE4F4EB),
    warning: Color(0xFF9A5800),
    warningSoft: Color(0xFFFFF1D6),
    error: Color(0xFFB3261E),
    errorSoft: Color(0xFFFDE8E6),
    neutral: Color(0xFF5B6472),
    neutralSoft: Color(0xFFEEF0F3),
    fab: Color(0xFF141A22),
    onFab: Color(0xFFFFFFFF),
    navyTrack: Color(0x1FFFFFFF),
    skeletonHighlight: Color(0xFFFAFAFB),
    chartMuted: Color(0xFFD5D9E0),
    chartGrid: Color(0xFFEEEEF1),
    heatRamp: [
      Color(0xFFF1F1F3),
      Color(0xFFFFE6DF),
      Color(0xFFFFC2B2),
      Color(0xFFFF9478),
      Color(0xFFD2401F),
    ],
    navBorder: Color(0xFFECECEF),
    shadow: Color(0x141B2433),
    accentShadow: Color(0x47D2401F),
    primaryGradientEnd: Color(0xFFC8323A),
    headlineGradientEnd: Color(0xFF3D5A80),
  );

  /// Dark palette: deep navy surfaces, the same coral accent family, and
  /// lighter status and text colours so everything keeps 4.5:1 contrast.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF0F151C),
    surface: Color(0xFF18212B),
    border: Color(0xFF263240),
    surfaceMuted: Color(0xFF222C38),
    navy: Color(0xFF2C4664),
    navyMeshEnd: Color(0xFF2A5276),
    navyGlowTop: Color(0xCC35558A),
    navyGlowBottom: Color(0x99205062),
    textPrimary: Color(0xFFF1F3F6),
    textSecondary: Color(0xFF9AA4B1),
    textOnNavy: Color(0xFFFFFFFF),
    textOnNavyMuted: Color(0xFFBCC6D1),
    accent: Color(0xFFFF7A5C),
    accentStrong: Color(0xFFD2401F),
    onAccentStrong: Color(0xFFFFFFFF),
    accentText: Color(0xFFFF8F73),
    accentSoft: Color(0xFF3D2620),
    success: Color(0xFF5BD08F),
    successSoft: Color(0xFF173527),
    warning: Color(0xFFF2B34C),
    warningSoft: Color(0xFF3A2D14),
    error: Color(0xFFFF8A80),
    errorSoft: Color(0xFF3B1E1E),
    neutral: Color(0xFFA9B3C0),
    neutralSoft: Color(0xFF26303C),
    fab: Color(0xFFF1F3F6),
    onFab: Color(0xFF141A22),
    navyTrack: Color(0x24FFFFFF),
    skeletonHighlight: Color(0xFF2C3846),
    chartMuted: Color(0xFF3A4757),
    chartGrid: Color(0xFF263240),
    heatRamp: [
      Color(0xFF222C38),
      Color(0xFF3A2622),
      Color(0xFF5E2E22),
      Color(0xFF8E3822),
      Color(0xFFD2401F),
    ],
    navBorder: Color(0xFF263240),
    shadow: Color(0x66000000),
    accentShadow: Color(0x40D2401F),
    primaryGradientEnd: Color(0xFFC8323A),
    headlineGradientEnd: Color(0xFFB9CCE4),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      border: c(border, other.border),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      navy: c(navy, other.navy),
      navyMeshEnd: c(navyMeshEnd, other.navyMeshEnd),
      navyGlowTop: c(navyGlowTop, other.navyGlowTop),
      navyGlowBottom: c(navyGlowBottom, other.navyGlowBottom),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textOnNavy: c(textOnNavy, other.textOnNavy),
      textOnNavyMuted: c(textOnNavyMuted, other.textOnNavyMuted),
      accent: c(accent, other.accent),
      accentStrong: c(accentStrong, other.accentStrong),
      onAccentStrong: c(onAccentStrong, other.onAccentStrong),
      accentText: c(accentText, other.accentText),
      accentSoft: c(accentSoft, other.accentSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      error: c(error, other.error),
      errorSoft: c(errorSoft, other.errorSoft),
      neutral: c(neutral, other.neutral),
      neutralSoft: c(neutralSoft, other.neutralSoft),
      fab: c(fab, other.fab),
      onFab: c(onFab, other.onFab),
      navyTrack: c(navyTrack, other.navyTrack),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
      chartMuted: c(chartMuted, other.chartMuted),
      chartGrid: c(chartGrid, other.chartGrid),
      heatRamp: [
        for (var i = 0; i < heatRamp.length; i++)
          c(heatRamp[i], other.heatRamp[i]),
      ],
      navBorder: c(navBorder, other.navBorder),
      shadow: c(shadow, other.shadow),
      accentShadow: c(accentShadow, other.accentShadow),
      primaryGradientEnd: c(primaryGradientEnd, other.primaryGradientEnd),
      headlineGradientEnd: c(headlineGradientEnd, other.headlineGradientEnd),
    );
  }
}

/// `context.colors` reads the active [AppPalette]. Falls back to the light
/// palette when the theme has none (e.g. a bare `MaterialApp` in tests).
extension AppColorsContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
