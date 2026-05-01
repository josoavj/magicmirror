/// Modele pour les parametres de l'application
import 'package:magicmirror/core/constants/app_constants.dart';

class AppSettings {
  final bool darkMode;
  final String locale;
  final bool enableNotifications;
  final bool enableLocationTracking;
  final String defaultCity;
  final bool syncCalendarOnStartup;
  final bool enableAudioFeedback;
  final bool ttsEnabled;
  final String ttsLanguage;
  final bool ttsAnnounceMorphology;
  final double ttsSpeechRate;
  final double ttsPitch;
  final int ttsMinRepeatSeconds;
  final bool ttsInterruptCurrent;
  final bool cameraFlipped;
  final double cameraZoom;
  final double cameraExposureOffset;
  final String cameraFlashMode;
  final int mirrorHudDisplaySeconds;
  final int mirrorHudCycleMinutes;
  final String appVersion;

  AppSettings({
    required this.darkMode,
    required this.locale,
    required this.enableNotifications,
    required this.enableLocationTracking,
    required this.defaultCity,
    required this.syncCalendarOnStartup,
    required this.enableAudioFeedback,
    required this.ttsEnabled,
    required this.ttsLanguage,
    required this.ttsAnnounceMorphology,
    required this.ttsSpeechRate,
    required this.ttsPitch,
    required this.ttsMinRepeatSeconds,
    required this.ttsInterruptCurrent,
    required this.cameraFlipped,
    required this.cameraZoom,
    required this.cameraExposureOffset,
    required this.cameraFlashMode,
    required this.mirrorHudDisplaySeconds,
    required this.mirrorHudCycleMinutes,
    required this.appVersion,
  });

  /// Valeurs par defaut
  factory AppSettings.defaults() {
    return AppSettings(
      darkMode: true,
      locale: 'fr_FR',
      enableNotifications: true,
      enableLocationTracking: true,
      defaultCity: 'Antananarivo',
      syncCalendarOnStartup: true,
      enableAudioFeedback: true,
      ttsEnabled: true,
      ttsLanguage: 'fr-FR',
      ttsAnnounceMorphology: true,
      ttsSpeechRate: 0.50,
      ttsPitch: 1.00,
      ttsMinRepeatSeconds: 45,
      ttsInterruptCurrent: true,
      cameraFlipped: false,
      cameraZoom: 1.0,
      cameraExposureOffset: 0.0,
      cameraFlashMode: 'off',
      mirrorHudDisplaySeconds: 30,
      mirrorHudCycleMinutes: 5,
      appVersion: AppConstants.appVersion,
    );
  }

  /// Copier avec modifications
  AppSettings copyWith({
    bool? darkMode,
    String? locale,
    bool? enableNotifications,
    bool? enableLocationTracking,
    String? defaultCity,
    bool? syncCalendarOnStartup,
    bool? enableAudioFeedback,
    bool? ttsEnabled,
    String? ttsLanguage,
    bool? ttsAnnounceMorphology,
    double? ttsSpeechRate,
    double? ttsPitch,
    int? ttsMinRepeatSeconds,
    bool? ttsInterruptCurrent,
    bool? cameraFlipped,
    double? cameraZoom,
    double? cameraExposureOffset,
    String? cameraFlashMode,
    int? mirrorHudDisplaySeconds,
    int? mirrorHudCycleMinutes,
    String? appVersion,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      locale: locale ?? this.locale,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableLocationTracking:
          enableLocationTracking ?? this.enableLocationTracking,
      defaultCity: defaultCity ?? this.defaultCity,
      syncCalendarOnStartup:
          syncCalendarOnStartup ?? this.syncCalendarOnStartup,
      enableAudioFeedback: enableAudioFeedback ?? this.enableAudioFeedback,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsAnnounceMorphology:
          ttsAnnounceMorphology ?? this.ttsAnnounceMorphology,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsMinRepeatSeconds: ttsMinRepeatSeconds ?? this.ttsMinRepeatSeconds,
      ttsInterruptCurrent: ttsInterruptCurrent ?? this.ttsInterruptCurrent,
      cameraFlipped: cameraFlipped ?? this.cameraFlipped,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      cameraExposureOffset: cameraExposureOffset ?? this.cameraExposureOffset,
      cameraFlashMode: cameraFlashMode ?? this.cameraFlashMode,
      mirrorHudDisplaySeconds:
          mirrorHudDisplaySeconds ?? this.mirrorHudDisplaySeconds,
      mirrorHudCycleMinutes:
          mirrorHudCycleMinutes ?? this.mirrorHudCycleMinutes,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
