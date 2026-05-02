import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary:              AppColors.primary,
      onPrimary:            AppColors.white,
      primaryContainer:     AppColors.primaryTint,
      onPrimaryContainer:   AppColors.primary,
      secondary:            AppColors.secondary,
      onSecondary:          AppColors.white,
      secondaryContainer:   AppColors.secondaryTint,
      onSecondaryContainer: AppColors.secondary,
      tertiary:             AppColors.accent,
      onTertiary:           AppColors.white,
      tertiaryContainer:    AppColors.accentTint,
      onTertiaryContainer:  AppColors.accent,
      error:                AppColors.danger,
      onError:              AppColors.white,
      errorContainer:       AppColors.dangerTint,
      onErrorContainer:     AppColors.danger,
      surface:              AppColors.white,
      onSurface:            AppColors.grey900,
      surfaceContainerHighest: AppColors.grey100,
      onSurfaceVariant:     AppColors.grey600,
      outline:              AppColors.grey300,
      outlineVariant:       AppColors.grey200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: _buildTextTheme(AppColors.grey900),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.grey900,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.grey200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.white,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.grey400),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.grey400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: AppColors.primaryTint,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.grey900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryTint,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:              Color(0xFF7A9DFF), // lightened #2F5BFF
      onPrimary:            Color(0xFF001270),
      primaryContainer:     Color(0xFF1A2E6B),
      onPrimaryContainer:   Color(0xFFBBCEFF),
      secondary:            Color(0xFFB39DFA), // lightened #7A5CFA
      onSecondary:          Color(0xFF2D0076),
      secondaryContainer:   Color(0xFF3D2080),
      onSecondaryContainer: Color(0xFFE0D4FF),
      tertiary:             Color(0xFF5EEAD4), // lightened #2EC4B6
      onTertiary:           Color(0xFF003730),
      tertiaryContainer:    Color(0xFF004D44),
      onTertiaryContainer:  Color(0xFFA8F0E8),
      error:                Color(0xFFFDA4A4), // lightened #FF6B6B
      onError:              Color(0xFF5C0000),
      errorContainer:       Color(0xFF7A1010),
      onErrorContainer:     Color(0xFFFFDAD6),
      surface:              Color(0xFF0E0F1A),  // dark navy
      onSurface:            Color(0xFFE8ECF5),
      surfaceContainerHighest: Color(0xFF1A1B2E), // dark navy card
      onSurfaceVariant:     Color(0xFF9AAABF),
      outline:              Color(0xFF344060),
      outlineVariant:       Color(0xFF1E2B48),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0B16),
      textTheme: _buildTextTheme(const Color(0xFFE8ECF5)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E0F1A),
        foregroundColor: Color(0xFFE8ECF5),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1A1B2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E2B48)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A9DFF),
          foregroundColor: const Color(0xFF001270),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1B2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF344060)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7A9DFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFDA4A4)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFDA4A4), width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E2B48),
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0E0F1A),
        selectedItemColor: Color(0xFF7A9DFF),
        unselectedItemColor: AppColors.grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7A9DFF),
        foregroundColor: Color(0xFF001270),
        elevation: 4,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge:  AppTextStyles.displayLarge.copyWith(color: color),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: color),
      displaySmall:  AppTextStyles.displaySmall.copyWith(color: color),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: color),
      headlineMedium:AppTextStyles.headlineMedium.copyWith(color: color),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: color),
      bodyLarge:     AppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium:    AppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall:     AppTextStyles.bodySmall.copyWith(color: color),
      labelLarge:    AppTextStyles.labelLarge.copyWith(color: color),
      labelMedium:   AppTextStyles.labelMedium.copyWith(color: color),
    );
  }
}
