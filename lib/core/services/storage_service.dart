import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageServiceImpl();
});

abstract class StorageService {
  Future<void> saveString(String key, String value, {bool secure = false});
  Future<String?> getString(String key, {bool secure = false});
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> saveList(String key, List<String> value);
  Future<List<String>?> getList(String key);
  Future<void> remove(String key, {bool secure = false});
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> saveString(String key, String value, {bool secure = false}) async {
    if (secure) {
      await _secureStorage.write(key: key, value: value);
    } else {
      final prefs = await _instance;
      await prefs.setString(key, value);
    }
  }

  @override
  Future<String?> getString(String key, {bool secure = false}) async {
    if (secure) {
      return await _secureStorage.read(key: key);
    } else {
      final prefs = await _instance;
      return prefs.getString(key);
    }
  }

  @override
  Future<void> saveInt(String key, int value) async {
    final prefs = await _instance;
    await prefs.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await _instance;
    return prefs.getInt(key);
  }

  @override
  Future<void> saveDouble(String key, double value) async {
    final prefs = await _instance;
    await prefs.setDouble(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    final prefs = await _instance;
    return prefs.getDouble(key);
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    final prefs = await _instance;
    await prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await _instance;
    return prefs.getBool(key);
  }

  @override
  Future<void> saveList(String key, List<String> value) async {
    final prefs = await _instance;
    await prefs.setStringList(key, value);
  }

  @override
  Future<List<String>?> getList(String key) async {
    final prefs = await _instance;
    return prefs.getStringList(key);
  }

  @override
  Future<void> remove(String key, {bool secure = false}) async {
    if (secure) {
      await _secureStorage.delete(key: key);
    } else {
      final prefs = await _instance;
      await prefs.remove(key);
    }
  }

  @override
  Future<void> clear() async {
    await _secureStorage.deleteAll();
    final prefs = await _instance;
    await prefs.clear();
  }
}
