import 'package:flutter/material.dart';

enum AppColorSchemeType { blue, purple, green }

class AppColorPalette {
  final AppColorSchemeType type;
  final String label;
  final Color primary;
  final Color primaryDark;
  final Color gradientEnd;
  final Color tint;
  final Color secondaryTint;
  /// Positive / income indicator color (light variant).
  final Color income;
  /// Negative / expense indicator color (dark variant).
  final Color expense;
  /// 10-color palette used for category charts (donut, bars).
  final List<Color> chartColors;

  const AppColorPalette({
    required this.type,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.gradientEnd,
    required this.tint,
    required this.secondaryTint,
    required this.income,
    required this.expense,
    required this.chartColors,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, gradientEnd],
      );

  static const blue = AppColorPalette(
    type: AppColorSchemeType.blue,
    label: 'Azul',
    primary:       Color(0xFF2F5BFF),
    primaryDark:   Color(0xFF1E3FC2),
    gradientEnd:   Color(0xFF7A5CFA),
    tint:          Color(0xFFEEF2FF),
    secondaryTint: Color(0xFFF5F0FF),
    income:        Color(0xFF93C5FD), // blue-300 — light/positive
    expense:       Color(0xFF1E40AF), // blue-800 — dark/heavy
    chartColors: [
      Color(0xFF2F5BFF),
      Color(0xFF60A5FA),
      Color(0xFF1E3FC2),
      Color(0xFF93C5FD),
      Color(0xFF7A5CFA),
      Color(0xFF3B82F6),
      Color(0xFF1E40AF),
      Color(0xFFBAE6FD),
      Color(0xFF4F46E5),
      Color(0xFF6366F1),
    ],
  );

  static const purple = AppColorPalette(
    type: AppColorSchemeType.purple,
    label: 'Morado',
    primary:       Color(0xFF7C3AED),
    primaryDark:   Color(0xFF5B21B6),
    gradientEnd:   Color(0xFFA855F7),
    tint:          Color(0xFFF5F0FF),
    secondaryTint: Color(0xFFFDF4FF),
    income:        Color(0xFFC4B5FD), // purple-300 — light/positive
    expense:       Color(0xFF5B21B6), // purple-800 — dark/heavy
    chartColors: [
      Color(0xFF7C3AED),
      Color(0xFFA855F7),
      Color(0xFF5B21B6),
      Color(0xFFC4B5FD),
      Color(0xFF8B5CF6),
      Color(0xFF6D28D9),
      Color(0xFFDDD6FE),
      Color(0xFF9333EA),
      Color(0xFF4C1D95),
      Color(0xFFD8B4FE),
    ],
  );

  static const green = AppColorPalette(
    type: AppColorSchemeType.green,
    label: 'Verde',
    primary:       Color(0xFF059669),
    primaryDark:   Color(0xFF047857),
    gradientEnd:   Color(0xFF10B981),
    tint:          Color(0xFFECFDF5),
    secondaryTint: Color(0xFFF0FDF4),
    income:        Color(0xFF2EC4B6), // teal — classic income
    expense:       Color(0xFFFF6B6B), // coral — classic expense
    chartColors: [
      Color(0xFF2F5BFF),
      Color(0xFF2EC4B6),
      Color(0xFFFF6B6B),
      Color(0xFFF59E0B),
      Color(0xFF7A5CFA),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFF84CC16),
      Color(0xFFFB923C),
      Color(0xFFA78BFA),
    ],
  );

  static const List<AppColorPalette> all = [blue, purple, green];

  static AppColorPalette fromType(AppColorSchemeType t) =>
      all.firstWhere((p) => p.type == t);
}
