import 'dart:async';
import 'log_storage_stub.dart'
    if (dart.library.io) 'log_storage_io.dart';

abstract class LogStorage {
  factory LogStorage() => getLogStorage();
  
  Future<void> initialize();
  Future<void> writeLog(String message);
  Future<void> clear();
  String? get directoryPath;
  Future<List<String>> getLogFilesPaths();
}
