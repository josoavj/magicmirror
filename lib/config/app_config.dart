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
  static const bool enableSecondaryLlmRanking = true;
  static const double secondaryLlmWeight = 0.25;
  static const String secondaryLlmModelTag = 'secondary';
  static const bool enableLlamaProfileContext = true;
  static const bool enableLlamaStrictGenderFilter = true;
  static const int outfitRecentCooldownDays = 3;
  static const int outfitRecentWindowDays = 10;
  static const int outfitDailyVarietyJitterMax = 8;
  static const int outfitDiversityPenaltyScale = 22;
  static const bool enableCreativeOutfitMix = true;
  static const double outfitCreativeExplorationShare = 0.35;
  static const int outfitCreativeBoost = 8;

  // App Settings
  static const bool enableDarkMode = false;
  static const Locale defaultLocale = Locale('fr', 'FR');

  // Debugging
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration weatherCurrentCacheTtl = Duration(minutes: 20);
  static const Duration weatherForecastCacheTtl = Duration(minutes: 45);
  static const Duration weatherStaleFallbackMaxAge = Duration(hours: 12);
  static const int weatherCoordinatePrecision = 2;

  // Supabase Auth redirects
  // Replace with your hosted confirmation page URL configured in Supabase.
  static const String supabaseAuthEmailRedirectUrl =
      'https://josoavj.github.io/magicmirrorverifauth/';

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
      'Météo: ${enableWeatherIntegration ? "ON" : "OFF"}',
      tag: 'Features',
    );
    logger.info(
      'Tenues: ${enableOutfitSuggestions ? "ON" : "OFF"}',
      tag: 'Features',
    );
    logger.info(
      'Second LLM: ${enableSecondaryLlmRanking ? "ON" : "OFF"} (w=${secondaryLlmWeight.toStringAsFixed(2)})',
      tag: 'Features',
    );
    logger.info('========== OK ==========', tag: 'MagicMirror');
  }
}
