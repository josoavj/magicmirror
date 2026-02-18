class AppConstants {
  // App Info
  static const String appName = 'Magic Mirror';
  static const String appVersion = '1.0.0';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Camera
  static const int cameraFps = 30;
  static const String cameraResolution = '1080p';

  // ML Model
  static const String morphologyModel = 'morphology_detection';
  static const int mlConfidenceThreshold = 80;

  // Locations
  static const double defaultLatitude = 48.8566;
  static const double defaultLongitude = 2.3522;
}
