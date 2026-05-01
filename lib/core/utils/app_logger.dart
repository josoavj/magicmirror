import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { info, warning, error, debug }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late Directory _logsDirectory;
  late File _currentLogFile;
  bool _isInitialized = false;
  final int _maxLogFileSize = 5 * 1024 * 1024; // 5 MB

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  /// Initialise le système de logging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logsDirectory = await _getLogsDirectory();

      if (!_logsDirectory.existsSync()) {
        _logsDirectory.createSync(recursive: true);
      }

      _currentLogFile = File(
        '${_logsDirectory.path}/magicmirror_${_getDateString()}.log',
      );

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

  /// Obtient le répertoire approprié selon la plateforme
  Future<Directory> _getLogsDirectory() async {
    if (Platform.isAndroid) {
      final appDir = await getExternalCacheDirectories();
      if (appDir != null && appDir.isNotEmpty) {
        return Directory('${appDir[0].path}/logs');
      }
      final tempDir = await getTemporaryDirectory();
      return Directory('${tempDir.path}/logs');
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      return Directory('${appDir.path}/logs');
    } else if (Platform.isLinux) {
      final cacheDir = await getApplicationCacheDirectory();
      return Directory('${cacheDir.path}/logs');
    } else if (Platform.isWindows) {
      final appDir = await getApplicationSupportDirectory();
      return Directory('${appDir.path}/logs');
    } else if (Platform.isMacOS) {
      final appDir = await getApplicationSupportDirectory();
      return Directory('${appDir.path}/logs');
    }

    // Fallback
    final tempDir = await getTemporaryDirectory();
    return Directory('${tempDir.path}/magicmirror/logs');
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

    if (!_isInitialized) {
      _logToConsole(message, level: level, tag: tag, error: error);
      return;
    }

    final timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(DateTime.now());
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] [$levelStr] [$tag] $message';

    // Log dans la console en debug
    _logToConsole(message, level: level, tag: tag, error: error);

    // Écrit dans le fichier
    try {
      // Vérifie la taille du fichier courant
      if (_currentLogFile.existsSync()) {
        final fileSize = _currentLogFile.lengthSync();
        if (fileSize > _maxLogFileSize) {
          // Rotation du fichier
          await _rotateLogFile();
        }
      }

      // Écrit le message
      await _currentLogFile.writeAsString(
        '$logMessage\n',
        mode: FileMode.append,
      );

      // Écrit le stack trace si disponible
      if (error != null) {
        await _currentLogFile.writeAsString(
          'Error: $error\n',
          mode: FileMode.append,
        );
      }

      if (stackTrace != null) {
        await _currentLogFile.writeAsString(
          'StackTrace:\n$stackTrace\n',
          mode: FileMode.append,
        );
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

  /// Effectue une rotation du fichier de log
  Future<void> _rotateLogFile() async {
    try {
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final archivedFile = File(
        '${_logsDirectory.path}/magicmirror_archived_$timestamp.log',
      );

      await _currentLogFile.rename(archivedFile.path);
      _currentLogFile = File(
        '${_logsDirectory.path}/magicmirror_${_getDateString()}.log',
      );

      // Nettoie les anciens fichiers (garde seulement les 7 derniers)
      await _cleanOldLogFiles();
    } catch (e) {
      debugPrint('[AppLogger] Erreur rotation: $e');
    }
  }

  /// Nettoie les anciens fichiers de log (garde les 7 derniers)
  Future<void> _cleanOldLogFiles() async {
    try {
      final files = _logsDirectory.listSync().whereType<File>().toList();
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      if (files.length > 7) {
        for (int i = 7; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      debugPrint('[AppLogger] Erreur nettoyage: $e');
    }
  }

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

  /// Obtient la chaîne de date pour le nom du fichier
  String _getDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Retourne le chemin du répertoire de logs
  String? getLogsDirectoryPath() {
    if (_isInitialized) {
      return _logsDirectory.path;
    }
    return null;
  }

  /// Retourne tous les fichiers de logs
  List<File> getLogFiles() {
    if (!_isInitialized) return [];
    try {
      return _logsDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.log'))
          .toList();
    } catch (e) {
      debugPrint('[AppLogger] Erreur lecture fichiers: $e');
      return [];
    }
  }

  /// Efface tous les logs
  Future<void> clearLogs() async {
    if (!_isInitialized) return;
    try {
      final files = getLogFiles();
      for (final file in files) {
        await file.delete();
      }
      _currentLogFile = File(
        '${_logsDirectory.path}/magicmirror_${_getDateString()}.log',
      );
      await info('Logs cleared', tag: 'AppLogger');
    } catch (e) {
      debugPrint('[AppLogger] Erreur suppression: $e');
    }
  }

  /// Exporte les logs dans un fichier texte
  Future<String?> exportLogs() async {
    if (!_isInitialized) return null;
    try {
      final files = getLogFiles();
      final buffer = StringBuffer();

      for (final file in files) {
        final content = file.readAsStringSync();
        buffer.writeln('=== ${file.path} ===');
        buffer.writeln(content);
        buffer.writeln('');
      }

      final exportFile = File(
        '${_logsDirectory.path}/magicmirror_export_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.txt',
      );
      await exportFile.writeAsString(buffer.toString());

      return exportFile.path;
    } catch (e) {
      debugPrint('[AppLogger] Erreur export: $e');
      return null;
    }
  }

  /// Ferme les ressources du logger (fichiers, etc.)
  Future<void> dispose() async {
    try {
      if (_currentLogFile.existsSync()) {
        debugPrint('[AppLogger] Closing log file');
      }
      _isInitialized = false;
    } catch (e) {
      debugPrint('[AppLogger] Erreur dispose: $e');
    }
  }
}

/// Instance globale du logger
final logger = AppLogger();
