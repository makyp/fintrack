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

  const AppColorPalette({
    required this.type,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.gradientEnd,
    required this.tint,
    required this.secondaryTint,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, gradientEnd],
      );

  static const blue = AppColorPalette(
    type: AppColorSchemeType.blue,
    label: 'Azul',
    primary:      Color(0xFF2F5BFF),
    primaryDark:  Color(0xFF1E3FC2),
    gradientEnd:  Color(0xFF7A5CFA),
    tint:         Color(0xFFEEF2FF),
    secondaryTint:Color(0xFFF5F0FF),
  );

  static const purple = AppColorPalette(
    type: AppColorSchemeType.purple,
    label: 'Morado',
    primary:      Color(0xFF7C3AED),
    primaryDark:  Color(0xFF5B21B6),
    gradientEnd:  Color(0xFFA855F7),
    tint:         Color(0xFFF5F0FF),
    secondaryTint:Color(0xFFFDF4FF),
  );

  static const green = AppColorPalette(
    type: AppColorSchemeType.green,
    label: 'Verde',
    primary:      Color(0xFF059669),
    primaryDark:  Color(0xFF047857),
    gradientEnd:  Color(0xFF10B981),
    tint:         Color(0xFFECFDF5),
    secondaryTint:Color(0xFFF0FDF4),
  );

  static const List<AppColorPalette> all = [blue, purple, green];

  static AppColorPalette fromType(AppColorSchemeType t) =>
      all.firstWhere((p) => p.type == t);
}
