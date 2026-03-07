import 'dart:async';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../features/agenda/data/models/event_model.dart';

class GoogleCalendarService {
  // Singleton
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;

  GoogleCalendarService._internal();

  // Variable pour tracker l'utilisateur actuel
  GoogleSignInAccount? _currentUser;

  /// Accès au singleton GoogleSignIn
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Getter pour l'utilisateur actuel
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Initialiser le service Google SignIn
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _log('GoogleSignIn initialized');

      // Écouter les événements d'authentification
      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          _log('User signed in: ${event.user.email}');
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _log('User signed out');
        }
      });
    } catch (e) {
      _log('Erreur lors de l\'initialisation de GoogleSignIn: $e');
    }
  }

  /// Vérifie la connexion et récupère le client API
  Future<calendar.CalendarApi?> _getCalendarApi() async {
    try {
      final account = await _ensureSignedIn();
      if (account == null) return null;

      // Demander les scopes nécessaires
      const scopes = [
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events.readonly',
      ];

      // Obtenir l'autorisation pour les scopes
      final authorization = await account.authorizationClient.authorizeScopes(
        scopes,
      );

      // Créer un client HTTP authentifié
      final httpClient = _createAuthenticatedClient(authorization.accessToken);
      return calendar.CalendarApi(httpClient);
    } catch (e) {
      _log('Erreur lors de l\'initialisation de l\'API: $e');
      return null;
    }
  }

  /// Crée un client HTTP authentifié avec le token d'accès
  http.Client _createAuthenticatedClient(String accessToken) {
    return auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [],
      ),
    );
  }

  /// RÉCUPÉRER les événements
  Future<List<AgendaEvent>> getUpcomingEvents({
    int maxResults = 20,
    DateTime? startDate,
  }) async {
    final api = await _getCalendarApi();
    if (api == null) return [];

    try {
      final now = startDate ?? DateTime.now();
      final events = await api.events.list(
        'primary',
        timeMin: now.toUtc(),
        maxResults: maxResults,
        orderBy: 'startTime',
        singleEvents: true,
      );

      return _convertEventsToModel(events.items ?? []);
    } catch (e) {
      _log('Erreur lors de la récupération des événements: $e');
      return [];
    }
  }

  /// RÉCUPÉRER les événements d'aujourd'hui
  Future<List<AgendaEvent>> getTodayEvents() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final api = await _getCalendarApi();
    if (api == null) return [];

    try {
      final events = await api.events.list(
        'primary',
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
      );

      return _convertEventsToModel(events.items ?? []);
    } catch (e) {
      _log('Erreur lors de la récupération des événements d\'aujourd\'hui: $e');
      return [];
    }
  }

  /// CRÉER un événement
  Future<AgendaEvent?> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    final api = await _getCalendarApi();
    if (api == null) return null;

    try {
      final event = calendar.Event(
        summary: title,
        description: description,
        location: location,
        start: calendar.EventDateTime(dateTime: startTime.toUtc()),
        end: calendar.EventDateTime(dateTime: endTime.toUtc()),
      );

      final created = await api.events.insert(event, 'primary');

      return AgendaEvent(
        id: created.id ?? const Uuid().v4(),
        title: created.summary ?? 'Sans titre',
        description: created.description,
        startTime: startTime,
        endTime: endTime,
        location: created.location,
        eventType: 'Google',
      );
    } catch (e) {
      _log('Erreur lors de la création: $e');
      return null;
    }
  }

  /// METTRE À JOUR un événement
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    final api = await _getCalendarApi();
    if (api == null) return false;

    try {
      final event = calendar.Event(
        summary: title,
        description: description,
        location: location,
        start: calendar.EventDateTime(dateTime: startTime.toUtc()),
        end: calendar.EventDateTime(dateTime: endTime.toUtc()),
      );

      await api.events.update(event, 'primary', eventId);
      return true;
    } catch (e) {
      _log('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  /// SUPPRIMER un événement
  Future<bool> deleteEvent(String eventId) async {
    final api = await _getCalendarApi();
    if (api == null) return false;

    try {
      await api.events.delete('primary', eventId);
      return true;
    } catch (e) {
      _log('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// LOGIN - Authentifier l'utilisateur
  Future<bool> signIn() async {
    try {
      final user = await _ensureSignedIn();
      return user != null;
    } catch (e) {
      _log('Erreur lors de la connexion: $e');
      return false;
    }
  }

  /// LOGOUT
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _log('Utilisateur déconnecté');
  }

  /// GESTION DE LA CONNEXION
  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    try {
      var user = _currentUser;

      // Si l'utilisateur n'est pas connecté, tenter une authentification légère
      if (user == null) {
        user = await _googleSignIn.attemptLightweightAuthentication();
        if (user != null) {
          _currentUser = user;
          return user;
        }
      } else {
        return user;
      }

      // Si toujours pas connecté, demander l'authentification complète
      if (_googleSignIn.supportsAuthenticate()) {
        user = await _googleSignIn.authenticate();
        _currentUser = user;
      }

      return user;
    } catch (e) {
      _log('Échec de l\'authentification Google: $e');
      return null;
    }
  }

  /// CONVERSION DES MODÈLES
  List<AgendaEvent> _convertEventsToModel(List<calendar.Event> events) {
    return events
        .map((e) {
          // Gestion des dates "All Day" (date) vs "Timed" (dateTime)
          final start = e.start?.dateTime ?? e.start?.date;
          final end = e.end?.dateTime ?? e.end?.date;

          if (start == null) return null;

          return AgendaEvent(
            id: e.id ?? const Uuid().v4(),
            title: e.summary ?? 'Sans titre',
            description: e.description,
            startTime: start.toLocal(),
            endTime: end?.toLocal() ?? start.add(const Duration(hours: 1)),
            location: e.location,
            eventType: 'Google',
          );
        })
        .whereType<AgendaEvent>()
        .toList();
  }

  /// Utilitaire de log propre
  void _log(String message) {
    logger.info(message, tag: 'GoogleCalendarService');
  }
}
