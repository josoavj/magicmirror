class AppConstants {
  // App Info
  static const String appName = 'Magic Mirror';
  static const String appVersion = '1.0.1-beta';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Camera
  static const int cameraFps = 30;
  static const String cameraResolution = '1080p';

  // ML Model
  static const String morphologyModel = 'morphology_detection';
  static const int mlConfidenceThreshold = 80;

  // ML Performance & Stabilization (Security fixes)
  static const int mlStabilizationFrames = 5;
  static const int mlHistorySize = 10;
  static const double mlShoulderSymmetryThreshold = 50.0; // pixels
  static const double mlRatioOutlierThreshold = 2.0; // sigma
  static const double mlMinValidRatio = 0.7;
  static const double mlMaxValidRatio = 1.5;
  static const double mlAsymmetryMaxClamp = 200.0;

  // ML Dynamic FPS
  static const int mlDelayVeryFast = 20; // <20ms
  static const int mlDelayFast = 35; // 20-35ms
  static const int mlDelayNormal = 50; // 35-50ms
  static const int mlDelaySlow = 100; // 50-100ms
  static const int mlDelayVerySlow = 150; // >100ms

  // Locations
  static const double defaultLatitude = 48.8566;
  static const double defaultLongitude = 2.3522;
}
