import 'package:flutter/material.dart';
import 'package:magicmirror/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData getTheme(bool isDarkMode) {
    final baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();

    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        surface: isDarkMode ? AppColors.background : Colors.white,
      ),
      scaffoldBackgroundColor: isDarkMode ? AppColors.background : Colors.white,
      textTheme: baseTheme.textTheme.apply(fontFamily: 'Lexend'),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'Lexend'),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      cardTheme: CardThemeData(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.glassBorder.withValues(
              alpha: AppColors.glassBorderOpacity,
            ),
            width: 1.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDarkMode ? Colors.white : AppColors.primary,
          side: BorderSide(
            color: (isDarkMode ? Colors.white : AppColors.primary).withValues(
              alpha: 0.28,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: (isDarkMode ? Colors.white : AppColors.primary)
              .withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkMode ? Colors.white : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}
