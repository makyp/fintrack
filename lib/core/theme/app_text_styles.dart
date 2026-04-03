import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // Display — Montserrat Bold — balances, totals
  static const displayLarge = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w700,
    fontSize: 40,
    letterSpacing: -1,
  );

  static const displayMedium = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: -0.5,
  );

  static const displaySmall = TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w700,
    fontSize: 24,
  );

  // Titles — Inter SemiBold
  static const headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 22,
  );

  static const headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static const headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // Body — Inter Regular
  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );

  static const labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  // Monospaced — Roboto Mono — amounts
  static const monoLarge = TextStyle(
    fontFamily: 'RobotoMono',
    fontWeight: FontWeight.w500,
    fontSize: 20,
  );

  static const monoMedium = TextStyle(
    fontFamily: 'RobotoMono',
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static const monoSmall = TextStyle(
    fontFamily: 'RobotoMono',
    fontWeight: FontWeight.w400,
    fontSize: 13,
  );

  // Income/expense specific
  static TextStyle incomeAmount({double fontSize = 20}) => TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: AppColors.success,
      );

  static TextStyle expenseAmount({double fontSize = 20}) => TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: AppColors.danger,
      );
}
