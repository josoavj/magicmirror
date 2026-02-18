import 'package:flutter/material.dart';

class AppConfig {
  // Environment
  static const String environment = 'development';
  static const bool isProduction = false;
  static const bool isDevelopment = true;

  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableWeatherIntegration = true;
  static const bool enableAgendaSync = true;
  static const bool enableOutfitSuggestions = true;

  // App Settings
  static const bool enableDarkMode = false;
  static const Locale defaultLocale = Locale('fr', 'FR');

  // Debugging
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;
}
