import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_color_scheme.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData light([AppColorPalette? palette]) =>
      _buildLight(palette ?? AppColorPalette.blue);

  static ThemeData _buildLight(AppColorPalette p) {
    final colorScheme = ColorScheme(
      brightness:              Brightness.light,
      primary:                 p.primary,
      onPrimary:               AppColors.white,
      primaryContainer:        p.tint,
      onPrimaryContainer:      p.primary,
      secondary:               p.gradientEnd,
      onSecondary:             AppColors.white,
      secondaryContainer:      p.secondaryTint,
      onSecondaryContainer:    p.gradientEnd,
      tertiary:                AppColors.accent,
      onTertiary:              AppColors.white,
      tertiaryContainer:       AppColors.accentTint,
      onTertiaryContainer:     AppColors.accent,
      error:                   AppColors.danger,
      onError:                 AppColors.white,
      errorContainer:          AppColors.dangerTint,
      onErrorContainer:        AppColors.danger,
      surface:                 AppColors.white,
      onSurface:               AppColors.grey900,
      surfaceContainerHighest: AppColors.grey100,
      onSurfaceVariant:        AppColors.grey600,
      outline:                 AppColors.grey300,
      outlineVariant:          AppColors.grey200,
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
          backgroundColor: const Color(0xFFFB923C),
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
          foregroundColor: const Color(0xFFFB923C),
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: Color(0xFFFB923C), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFB923C),
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
          borderSide: BorderSide(color: p.primary, width: 2),
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: p.primary,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.white,
        selectedIconTheme: IconThemeData(color: p.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.grey400),
        selectedLabelTextStyle: TextStyle(color: p.primary),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.grey400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: p.tint,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.grey900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.tint,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      // Material 3 NavigationBar — makes selected item clearly follow the theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.tint,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: p.primary);
          }
          return const IconThemeData(color: AppColors.grey500);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: p.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return const TextStyle(
            color: AppColors.grey500,
            fontWeight: FontWeight.normal,
            fontSize: 11,
          );
        }),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge:   AppTextStyles.displayLarge.copyWith(color: color),
      displayMedium:  AppTextStyles.displayMedium.copyWith(color: color),
      displaySmall:   AppTextStyles.displaySmall.copyWith(color: color),
      headlineLarge:  AppTextStyles.headlineLarge.copyWith(color: color),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: color),
      headlineSmall:  AppTextStyles.headlineSmall.copyWith(color: color),
      bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium:     AppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall:      AppTextStyles.bodySmall.copyWith(color: color),
      labelLarge:     AppTextStyles.labelLarge.copyWith(color: color),
      labelMedium:    AppTextStyles.labelMedium.copyWith(color: color),
    );
  }
}
