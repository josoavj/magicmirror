import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'log_storage.dart';

enum LogLevel { info, warning, error, debug }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  final LogStorage _storage = LogStorage();
  bool _isInitialized = false;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  /// Initialise le système de logging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _storage.initialize();
      _isInitialized = true;
      _logToConsole(
        'Logger initialized',
        level: LogLevel.info,
        tag: 'AppLogger',
      );
    } catch (e) {
      debugPrint('[AppLogger] Erreur initialization: $e');
    }
  }

  /// Enregistre un message dans les logs
  Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String tag = 'AppLogger',
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime.now());
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] [$levelStr] [$tag] $message';

    // Log dans la console en debug
    _logToConsole(message, level: level, tag: tag, error: error);

    // Écrit dans le stockage (si supporté)
    try {
      await _storage.writeLog(logMessage);
      if (error != null) {
        await _storage.writeLog('Error: $error');
      }
      if (stackTrace != null) {
        await _storage.writeLog('StackTrace:\n$stackTrace');
      }
    } catch (e) {
      debugPrint('[AppLogger] Erreur écriture log: $e');
    }
  }

  /// Enregistre un message d'info
  Future<void> info(String message, {String tag = 'AppLogger'}) =>
      log(message, level: LogLevel.info, tag: tag);

  /// Enregistre un avertissement
  Future<void> warning(String message, {String tag = 'AppLogger'}) =>
      log(message, level: LogLevel.warning, tag: tag);

  /// Enregistre une erreur
  Future<void> error(
    String message, {
    String tag = 'AppLogger',
    dynamic error,
    StackTrace? stackTrace,
  }) => log(
    message,
    level: LogLevel.error,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  /// Enregistre un message de debug
  Future<void> debug(String message, {String tag = 'AppLogger'}) =>
      log(message, level: LogLevel.debug, tag: tag);

  /// Affiche dans la console
  void _logToConsole(
    String message, {
    required LogLevel level,
    required String tag,
    dynamic error,
  }) {
    if (kDebugMode) {
      final levelStr = level.toString().split('.').last.toUpperCase();
      final output = '[$levelStr] [$tag] $message';

      if (level == LogLevel.error) {
        debugPrint('❌ $output');
        if (error != null) debugPrint('   Error: $error');
      } else if (level == LogLevel.warning) {
        debugPrint('⚠️  $output');
      } else if (level == LogLevel.debug) {
        debugPrint('🔍 $output');
      } else {
        debugPrint('ℹ️  $output');
      }
    }
  }

  /// Retourne le chemin du répertoire de logs
  String? getLogsDirectoryPath() => _storage.directoryPath;

  /// Efface tous les logs
  Future<void> clearLogs() async {
    await _storage.clear();
    await info('Logs cleared', tag: 'AppLogger');
  }

  /// Ferme les ressources du logger
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

/// Instance globale du logger
final logger = AppLogger();
