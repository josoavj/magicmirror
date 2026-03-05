/// Injection de Dépendances (Dependency Injection)
import '../data/services/google_calendar_service.dart';

class DISetup {
  // Singleton instances
  static late GoogleCalendarService _googleCalendarService;

  /// Getter pour accéder au service Google Calendar
  static GoogleCalendarService get googleCalendarService =>
      _googleCalendarService;

  static Future<void> setupDependencies() async {
    await _setupCoreServices();
    _setupDataSources();
    _setupRepositories();
    _setupProviders();
  }

  static Future<void> _setupCoreServices() async {
    // Initialiser le service Google Calendar
    _googleCalendarService = GoogleCalendarService();
    await _googleCalendarService.initialize();
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
