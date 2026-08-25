import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// App-wide [ThemeData]. Color values live in [AppColors]; these fields are
/// kept as aliases since screens/widgets already reference `AppTheme.*`.
class AppTheme {
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surfaceSolid;
  static const Color surfaceHigh = AppColors.surfaceHigh;
  static const Color border = AppColors.border;
  static const Color textMuted = AppColors.textMuted;
  static const Color gold = AppColors.gold;
  static const Color accent = AppColors.purple;
  static const Color red = AppColors.danger;

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.gold,
      surface: AppColors.surfaceSolid,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTypography.heading,
        contentTextStyle: AppTypography.bodyMuted,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceSolid,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 50),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        hintStyle: AppTypography.bodyMuted,
        labelStyle: AppTypography.bodyMuted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smRadius,
          borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.purple.withValues(alpha: 0.28),
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.body.copyWith(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: AppTypography.body,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceSolid,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.caption.copyWith(color: AppColors.gold, fontSize: 11),
        unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 11),
      ),
    );
  }
}
