import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized text styles. Display/headline text uses Baloo 2 (chunky,
/// rounded — the "game" feel from the brand mark); body/UI text uses
/// Nunito, which pairs cleanly with it at small sizes.
class AppTypography {
  AppTypography._();

  static TextStyle get _display => GoogleFonts.baloo2();
  static TextStyle get _body => GoogleFonts.nunito();

  /// Big hero numbers (Life Score) and the in-app wordmark.
  static TextStyle get hero => _display.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1,
      );

  /// Screen/section titles, e.g. "CREATE YOUR PROFILE".
  static TextStyle get title => _display.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get heading => _display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _body.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMuted => _body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => _body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  /// All-caps button label style.
  static TextStyle get button => _body.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      );

  static TextStyle get eyebrow => _body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: AppColors.textMuted,
      );
}
