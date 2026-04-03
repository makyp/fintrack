import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // Display — Montserrat Bold — balances, totals
  static final displayLarge = GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: 40,
    letterSpacing: -1,
  );

  static final displayMedium = GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: -0.5,
  );

  static final displaySmall = GoogleFonts.montserrat(
    fontWeight: FontWeight.w700,
    fontSize: 24,
  );

  // Titles — Inter SemiBold
  static final headlineLarge = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );

  static final headlineMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static final headlineSmall = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // Body — Inter Regular
  static final bodyLarge = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static final bodyMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  static final bodySmall = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );

  static final labelLarge = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static final labelMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  // Monospaced — Roboto Mono — amounts
  static final monoLarge = GoogleFonts.robotoMono(
    fontWeight: FontWeight.w500,
    fontSize: 20,
  );

  static final monoMedium = GoogleFonts.robotoMono(
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static final monoSmall = GoogleFonts.robotoMono(
    fontWeight: FontWeight.w400,
    fontSize: 13,
  );

  // Income/expense specific
  static TextStyle incomeAmount({double fontSize = 20}) => GoogleFonts.robotoMono(
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: AppColors.success,
      );

  static TextStyle expenseAmount({double fontSize = 20}) => GoogleFonts.robotoMono(
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: AppColors.danger,
      );
}
