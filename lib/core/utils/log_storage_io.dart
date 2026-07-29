import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'log_storage.dart';
import 'package:magicmirror/core/utils/platform_helper.dart';

LogStorage getLogStorage() => LogStorageIO();

class LogStorageIO implements LogStorage {
  Directory? _logsDirectory;
  File? _currentLogFile;

  @override
  String? get directoryPath => _logsDirectory?.path;

  @override
  Future<void> initialize() async {
    try {
      _logsDirectory = await _getLogsDirectory();
      if (!_logsDirectory!.existsSync()) {
        _logsDirectory!.createSync(recursive: true);
      }
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      _currentLogFile = File('${_logsDirectory!.path}/magicmirror_$dateStr.log');
    } catch (e) {
      // Fail silently
    }
  }

  Future<Directory> _getLogsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS || PlatformHelper.isMacOS) {
      final appDir = await getApplicationSupportDirectory();
      return Directory('${appDir.path}/logs');
    } else if (PlatformHelper.isLinux) {
      final cacheDir = await getApplicationCacheDirectory();
      return Directory('${cacheDir.path}/logs');
    } else if (PlatformHelper.isWindows) {
      final appDir = await getApplicationSupportDirectory();
      return Directory('${appDir.path}/logs');
    }
    final tempDir = await getTemporaryDirectory();
    return Directory('${tempDir.path}/magicmirror/logs');
  }

  @override
  Future<void> writeLog(String message) async {
    if (_currentLogFile == null) return;
    try {
      await _currentLogFile!.writeAsString('$message\n', mode: FileMode.append);
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    if (_logsDirectory == null) return;
    try {
      if (_logsDirectory!.existsSync()) {
        _logsDirectory!.deleteSync(recursive: true);
        await initialize();
      }
    } catch (_) {}
  }

  @override
  Future<List<String>> getLogFilesPaths() async {
    if (_logsDirectory == null || !_logsDirectory!.existsSync()) return [];
    try {
      return _logsDirectory!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .map((f) => f.path)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
