import 'dart:async';
import 'log_storage.dart';

LogStorage getLogStorage() => LogStorageStub();

class LogStorageStub implements LogStorage {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> writeLog(String message) async {}

  @override
  Future<void> clear() async {}

  @override
  String? get directoryPath => null;

  @override
  Future<List<String>> getLogFilesPaths() async => [];
}
