import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

/// Text styles from the design system. Most widgets read them through
/// `Theme.of(context).textTheme`; the extra styles here cover big amounts
/// and the nav bar, which have no Material slot.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  /// Screen title 24 / 800, letter-spacing -0.02em.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48,
    color: AppColors.textPrimary,
  );

  /// Header name 18 / 700.
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Section title 17 / 700.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// List titles 15 / 600.
  static const TextStyle listTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Body 14 / 500.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Secondary label 13 / 500, e.g. "Welcome back".
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Caption 12 / 500, textSecondary.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Overline 11 / 600, letter-spacing 0.12em. Pass uppercase text.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.32,
    color: AppColors.textSecondary,
  );

  /// Form field label 13 / 600, shown above inputs.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Primary full-width button label 16 / 700.
  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Name on the navy profile card 20 / 800, white.
  static const TextStyle profileName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textOnNavy,
  );

  /// Initials inside the large avatar 26 / 800, coral text.
  static const TextStyle avatarInitialsLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.accentText,
  );

  /// Button label 14 / 700.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  /// Active bottom nav label 13 / 700.
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Big amounts 36 / 800.
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.72,
    color: AppColors.textPrimary,
  );

  /// The smaller, grey "ZMW" prefix in front of a big amount.
  static const TextStyle amountPrefix = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  /// The smaller, lighter decimals after a big amount.
  static const TextStyle amountDecimals = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  /// Percentage on the navy budget card 38 / 800.
  static const TextStyle percentLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.76,
    height: 1.1,
    color: AppColors.accent,
  );

  /// Stat tile values 17 / 800.
  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// Amounts in list rows 15 / 700.
  static const TextStyle listAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Card titles on navy 17 / 700, white.
  static const TextStyle cardTitleOnNavy = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textOnNavy,
  );

  /// Wordmark on the splash screen 28 / 800.
  static const TextStyle wordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.56,
    color: AppColors.textPrimary,
  );
}

/// Builds the app's [ThemeData].
abstract final class AppTheme {
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accentStrong,
    onPrimary: AppColors.surface,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.accentText,
    secondary: AppColors.navy,
    onSecondary: AppColors.textOnNavy,
    secondaryContainer: AppColors.surfaceMuted,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.success,
    onTertiary: AppColors.surface,
    tertiaryContainer: AppColors.successSoft,
    onTertiaryContainer: AppColors.success,
    error: AppColors.error,
    onError: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surfaceMuted,
    surfaceContainerHigh: AppColors.surfaceMuted,
    surfaceContainerHighest: AppColors.surfaceMuted,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    shadow: AppColors.shadow,
    inverseSurface: AppColors.navy,
    onInverseSurface: AppColors.textOnNavy,
    inversePrimary: AppColors.accent,
  );

  static const TextTheme _textTheme = TextTheme(
    displaySmall: AppTypography.amountLarge,
    headlineSmall: AppTypography.screenTitle,
    titleLarge: AppTypography.headerTitle,
    titleMedium: AppTypography.sectionTitle,
    titleSmall: AppTypography.listTitle,
    bodyLarge: AppTypography.listTitle,
    bodyMedium: AppTypography.body,
    bodySmall: AppTypography.caption,
    labelLarge: AppTypography.button,
    labelMedium: AppTypography.label,
    labelSmall: AppTypography.overline,
  );

  static RoundedRectangleBorder _rounded(double radius, {BorderSide? side}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );

  static const BorderSide _borderSide = BorderSide(color: AppColors.border);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    fontFamily: AppTypography.fontFamily,
    textTheme: _textTheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: _rounded(Dimens.radiusCard, side: _borderSide),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentStrong,
        foregroundColor: AppColors.surface,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, Dimens.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: _rounded(Dimens.radiusButton),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, Dimens.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: _borderSide,
        shape: _rounded(Dimens.radiusButton),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentText,
        textStyle: AppTypography.button,
        minimumSize: const Size(Dimens.minTouchTarget, Dimens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: _rounded(Dimens.radiusInput),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(Dimens.minTouchTarget, Dimens.minTouchTarget),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.navy,
      disabledColor: AppColors.surfaceMuted,
      checkmarkColor: AppColors.textOnNavy,
      labelStyle: AppTypography.body,
      secondaryLabelStyle: AppTypography.body.copyWith(
        color: AppColors.textOnNavy,
      ),
      side: _borderSide,
      shape: _rounded(Dimens.radiusInput, side: _borderSide),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
      border: _inputBorder(AppColors.border),
      enabledBorder: _inputBorder(AppColors.border),
      focusedBorder: _inputBorder(AppColors.accentStrong, width: 1.5),
      errorBorder: _inputBorder(AppColors.error),
      focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.surfaceMuted,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: AppTypography.body.copyWith(
        color: AppColors.textOnNavy,
      ),
      shape: _rounded(Dimens.radiusButton),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: _rounded(Dimens.radiusDialog),
      titleTextStyle: AppTypography.sectionTitle,
      contentTextStyle: AppTypography.body.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(Dimens.gapS),
      ),
      textStyle: AppTypography.caption.copyWith(color: AppColors.textOnNavy),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusInput),
        borderSide: BorderSide(color: color, width: width),
      );
}
