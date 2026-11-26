import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimens.dart';

/// Text sizes and weights from the design system, without colour.
///
/// Widgets use `context.text`, which adds the active palette's colours.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  /// Screen title 24 / 800, letter-spacing -0.02em.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48,
  );

  /// Header name 18 / 700.
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// Section title 17 / 700.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// List titles 15 / 600.
  static const TextStyle listTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// Body 14 / 500.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// Secondary label 13 / 500, e.g. "Welcome back".
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Caption 12 / 500.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Overline 11 / 600, letter-spacing 0.12em. Pass uppercase text.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.32,
  );

  /// Form field label 13 / 600, shown above inputs.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Primary full-width button label 16 / 700.
  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Name on the navy profile card 20 / 800.
  static const TextStyle profileName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  /// Initials inside the large avatar 26 / 800.
  static const TextStyle avatarInitialsLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
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
  );

  /// Status badge label 12 / 700.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// Big amounts 36 / 800.
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.72,
  );

  /// Amount in sheets and summary cards 30 / 800.
  static const TextStyle amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  /// The smaller "ZMW" prefix in front of a big amount.
  static const TextStyle amountPrefix = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// The smaller, lighter decimals after a big amount.
  static const TextStyle amountDecimals = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  /// Percentage on the navy budget card 38 / 800.
  static const TextStyle percentLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.76,
    height: 1.1,
  );

  /// Stat tile values 17 / 800.
  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  /// Amounts in list rows 15 / 700.
  static const TextStyle listAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Card titles on navy 17 / 700.
  static const TextStyle cardTitleOnNavy = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Wordmark on the splash screen 28 / 800.
  static const TextStyle wordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.56,
  );
}

/// The [AppTypography] styles coloured from one [AppPalette]. Read with
/// `context.text`.
class AppTextStyles {
  const AppTextStyles(this._c);

  final AppPalette _c;

  TextStyle get screenTitle =>
      AppTypography.screenTitle.copyWith(color: _c.textPrimary);
  TextStyle get headerTitle =>
      AppTypography.headerTitle.copyWith(color: _c.textPrimary);
  TextStyle get sectionTitle =>
      AppTypography.sectionTitle.copyWith(color: _c.textPrimary);
  TextStyle get listTitle =>
      AppTypography.listTitle.copyWith(color: _c.textPrimary);
  TextStyle get body => AppTypography.body.copyWith(color: _c.textPrimary);
  TextStyle get label => AppTypography.label.copyWith(color: _c.textSecondary);
  TextStyle get caption =>
      AppTypography.caption.copyWith(color: _c.textSecondary);
  TextStyle get overline =>
      AppTypography.overline.copyWith(color: _c.textSecondary);
  TextStyle get fieldLabel =>
      AppTypography.fieldLabel.copyWith(color: _c.textPrimary);
  TextStyle get primaryButton =>
      AppTypography.primaryButton.copyWith(color: _c.onAccentStrong);
  TextStyle get profileName =>
      AppTypography.profileName.copyWith(color: _c.textOnNavy);
  TextStyle get avatarInitialsLarge =>
      AppTypography.avatarInitialsLarge.copyWith(color: _c.accentText);
  TextStyle get button => AppTypography.button.copyWith(color: _c.textPrimary);
  TextStyle get navLabel =>
      AppTypography.navLabel.copyWith(color: _c.textPrimary);
  TextStyle get badge => AppTypography.badge.copyWith(color: _c.textPrimary);
  TextStyle get amountLarge =>
      AppTypography.amountLarge.copyWith(color: _c.textPrimary);
  TextStyle get amountMedium =>
      AppTypography.amountMedium.copyWith(color: _c.textPrimary);
  TextStyle get amountPrefix =>
      AppTypography.amountPrefix.copyWith(color: _c.textSecondary);
  TextStyle get amountDecimals =>
      AppTypography.amountDecimals.copyWith(color: _c.textSecondary);
  TextStyle get percentLarge =>
      AppTypography.percentLarge.copyWith(color: _c.accent);
  TextStyle get statValue =>
      AppTypography.statValue.copyWith(color: _c.textPrimary);
  TextStyle get listAmount =>
      AppTypography.listAmount.copyWith(color: _c.textPrimary);
  TextStyle get cardTitleOnNavy =>
      AppTypography.cardTitleOnNavy.copyWith(color: _c.textOnNavy);
  TextStyle get wordmark =>
      AppTypography.wordmark.copyWith(color: _c.textPrimary);
}

extension AppTextContext on BuildContext {
  AppTextStyles get text => AppTextStyles(colors);
}

/// Builds the app's light and dark [ThemeData] from the two palettes.
abstract final class AppTheme {
  static final ThemeData light = _build(AppPalette.light, Brightness.light);
  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);

  static ColorScheme _scheme(AppPalette c, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: c.accentStrong,
        onPrimary: c.onAccentStrong,
        primaryContainer: c.accentSoft,
        onPrimaryContainer: c.accentText,
        secondary: c.navy,
        onSecondary: c.textOnNavy,
        secondaryContainer: c.surfaceMuted,
        onSecondaryContainer: c.textPrimary,
        tertiary: c.success,
        onTertiary: c.surface,
        tertiaryContainer: c.successSoft,
        onTertiaryContainer: c.success,
        error: c.error,
        onError: c.surface,
        surface: c.surface,
        onSurface: c.textPrimary,
        onSurfaceVariant: c.textSecondary,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.background,
        surfaceContainer: c.surfaceMuted,
        surfaceContainerHigh: c.surfaceMuted,
        surfaceContainerHighest: c.surfaceMuted,
        outline: c.border,
        outlineVariant: c.border,
        shadow: c.shadow,
        inverseSurface: c.navy,
        onInverseSurface: c.textOnNavy,
        inversePrimary: c.accent,
      );

  static RoundedRectangleBorder _rounded(double radius, {BorderSide? side}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusInput),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final t = AppTextStyles(c);
    final borderSide = BorderSide(color: c.border);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _scheme(c, brightness),
      extensions: [c],
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        displaySmall: t.amountLarge,
        headlineSmall: t.screenTitle,
        titleLarge: t.headerTitle,
        titleMedium: t.sectionTitle,
        titleSmall: t.listTitle,
        bodyLarge: t.listTitle,
        bodyMedium: t.body,
        bodySmall: t.caption,
        labelLarge: AppTypography.button,
        labelMedium: t.label,
        labelSmall: t.overline,
      ),
      scaffoldBackgroundColor: c.background,
      // Pushed screens fade and drift forward instead of sliding abruptly.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      canvasColor: c.background,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t.screenTitle,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: _rounded(Dimens.radiusCard, side: borderSide),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accentStrong,
          foregroundColor: c.onAccentStrong,
          textStyle: AppTypography.button,
          minimumSize: const Size(0, Dimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: _rounded(Dimens.radiusButton),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.textPrimary,
          textStyle: AppTypography.button,
          minimumSize: const Size(0, Dimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: borderSide,
          shape: _rounded(Dimens.radiusButton),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentText,
          textStyle: AppTypography.button,
          minimumSize: const Size(Dimens.minTouchTarget, Dimens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: _rounded(Dimens.radiusInput),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(Dimens.minTouchTarget, Dimens.minTouchTarget),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.navy,
        disabledColor: c.surfaceMuted,
        checkmarkColor: c.textOnNavy,
        labelStyle: t.body,
        secondaryLabelStyle: t.body.copyWith(color: c.textOnNavy),
        side: borderSide,
        shape: _rounded(Dimens.radiusInput, side: borderSide),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: t.body.copyWith(color: c.textSecondary),
        labelStyle: t.body.copyWith(color: c.textSecondary),
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.accentStrong, width: 1.5),
        errorBorder: _inputBorder(c.error),
        focusedErrorBorder: _inputBorder(c.error, width: 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accentStrong,
        selectionHandleColor: c.accentStrong,
        selectionColor: c.accent.withValues(alpha: 0.3),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.navy,
        contentTextStyle: t.body.copyWith(color: c.textOnNavy),
        shape: _rounded(Dimens.radiusButton),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimens.radiusCard),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: _rounded(Dimens.radiusDialog),
        titleTextStyle: t.sectionTitle,
        contentTextStyle: t.body.copyWith(color: c.textSecondary),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.navy,
          borderRadius: BorderRadius.circular(Dimens.gapS),
        ),
        textStyle: t.caption.copyWith(color: c.textOnNavy),
      ),
    );
  }
}
