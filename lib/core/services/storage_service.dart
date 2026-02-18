/// Service pour gérer le stockage local (SharedPreferences, Hive, etc.)

abstract class StorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> saveList(String key, List<String> value);
  Future<List<String>?> getList(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  @override
  Future<void> saveString(String key, String value) async {
    // À implémenter
  }

  @override
  Future<String?> getString(String key) async {
    // À implémenter
    return null;
  }

  @override
  Future<void> saveInt(String key, int value) async {
    // À implémenter
  }

  @override
  Future<int?> getInt(String key) async {
    // À implémenter
    return null;
  }

  @override
  Future<void> saveDouble(String key, double value) async {
    // À implémenter
  }

  @override
  Future<double?> getDouble(String key) async {
    // À implémenter
    return null;
  }

  @override
  Future<void> saveList(String key, List<String> value) async {
    // À implémenter
  }

  @override
  Future<List<String>?> getList(String key) async {
    // À implémenter
    return null;
  }

  @override
  Future<void> remove(String key) async {
    // À implémenter
  }

  @override
  Future<void> clear() async {
    // À implémenter
  }
}
