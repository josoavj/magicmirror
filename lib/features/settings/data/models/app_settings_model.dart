/// Modele pour les parametres de l'application
class AppSettings {
  final bool darkMode;
  final String locale;
  final bool enableNotifications;
  final bool enableLocationTracking;
  final String defaultCity;
  final bool syncCalendarOnStartup;
  final bool enableAudioFeedback;
  final bool cameraFlipped;
  final double cameraZoom;
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
    required this.cameraFlipped,
    required this.cameraZoom,
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
      cameraFlipped: false,
      cameraZoom: 1.0,
      mirrorHudDisplaySeconds: 30,
      mirrorHudCycleMinutes: 5,
      appVersion: '1.0.0',
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
    bool? cameraFlipped,
    double? cameraZoom,
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
      cameraFlipped: cameraFlipped ?? this.cameraFlipped,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      mirrorHudDisplaySeconds:
          mirrorHudDisplaySeconds ?? this.mirrorHudDisplaySeconds,
      mirrorHudCycleMinutes:
          mirrorHudCycleMinutes ?? this.mirrorHudCycleMinutes,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
