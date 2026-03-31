class DISetup {
  static Future<void> setupDependencies() async {
    await _setupCoreServices();
    _setupDataSources();
    _setupRepositories();
    _setupProviders();
  }

  static Future<void> _setupCoreServices() async {
    // Point d'extension pour l'initialisation des services coeur.
  }

  static void _setupDataSources() {
    // TODO: Setup des data sources
  }

  static void _setupRepositories() {
    // TODO: Setup des repositories
  }

  static void _setupProviders() {
    // TODO: Setup des providers d'état
  }
}
