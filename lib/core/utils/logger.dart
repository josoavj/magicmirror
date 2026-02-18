/// Service de logging pour l'application

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _prefix = '[MagicMirror]';

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage =
        '$_prefix [$timestamp] ${level.name.toUpperCase()}: $message';

    // TODO: Implémentation du logging
    // Pour développement, on peut utiliser print()
    // Pour production, intégrer avec Firebase Crashlytics, Sentry, etc.

    if (error != null) {
      print('$logMessage\nError: $error');
    }
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
}
