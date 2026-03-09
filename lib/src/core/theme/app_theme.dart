import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const base = ColorScheme.dark(
      primary: AppColors.emerald,
      secondary: AppColors.lime,
      surface: Color(0xFF121514),
      error: AppColors.danger,
      onPrimary: Color(0xFFF1F5F9),
      onSurface: Color(0xFFF1F5F9),
    );

    return _theme(base, const Color(0xFF0A0C0B), const Color(0xFFF1F5F9), const Color(0xFF94A3B8));
  }

  static ThemeData light() {
    const base = ColorScheme.light(
      primary: AppColors.emerald,
      secondary: AppColors.lime,
      surface: Color(0xFFFFFFFF),
      error: AppColors.danger,
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
    );

    return _theme(base, const Color(0xFFF8FBF9), const Color(0xFF0F172A), const Color(0xFF475569));
  }

  static ThemeData _theme(
    ColorScheme colorScheme,
    Color scaffoldBackgroundColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      dividerColor: AppColors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textPrimary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald;
          }
          return textSecondary.withValues(alpha: 0.35);
        }),
      ),
    );
  }
}
