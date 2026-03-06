import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Secondary colors
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // Tertiary colors
  static const Color tertiary = Color(0xFF06B6D4);
  static const Color tertiaryDark = Color(0xFF0891B2);
  static const Color tertiaryLight = Color(0xFF22D3EE);

  // Accent colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Background colors
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textTertiary = Color(0xFFCBD5E1);
  static const Color textHint = Color(0xFF94A3B8);

  // Gradient colors
  static const List<Color> gradientPrimary = [primary, primaryDark];
  static const List<Color> gradientSecondary = [secondary, secondaryDark];
  static const List<Color> gradientWarning = [warning, accentDark];

  // Glass effect colors
  static const Color glassBackground = Color(0xFFFFFFFF);
  static const double glassOpacity = 0.08;
  static const Color glassBorder = Color(0xFFFFFFFF);
  static const double glassBorderOpacity = 0.15;
}
