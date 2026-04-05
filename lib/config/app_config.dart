import 'package:flutter/material.dart';
import 'package:magicmirror/core/utils/app_logger.dart';

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
  static const bool enableCloudFeedbackExport = true;
  static const bool enableHybridMlRanking = true;
  static const double hybridMlWeight = 0.4;

  // App Settings
  static const bool enableDarkMode = false;
  static const Locale defaultLocale = Locale('fr', 'FR');

  // Debugging
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 24);

  /// Affiche le statut de configuration de l'application
  static Future<void> printStartupInfo() async {
    logger.info('========== START ==========', tag: 'MagicMirror');
    logger.info(
      'Mode: ${isDevelopment ? "Développement" : "Production"}',
      tag: 'Config',
    );
    logger.info('Agenda Supabase', tag: 'Calendrier');
    logger.info('AI: ${enableAIFeatures ? "ON" : "OFF"}', tag: 'Features');
    logger.info(
      'Meteo: ${enableWeatherIntegration ? "ON" : "OFF"}',
      tag: 'Features',
    );
    logger.info(
      'Tenues: ${enableOutfitSuggestions ? "ON" : "OFF"}',
      tag: 'Features',
    );
    logger.info('========== OK ==========', tag: 'MagicMirror');
  }
}
