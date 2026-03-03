import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:uuid/uuid.dart';

// Note: Assurez-vous que le chemin vers votre modèle est correct
import '../../features/agenda/data/models/event_model.dart';

class GoogleCalendarService {
  // Singleton
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;

  // Configuration de Google Sign-In avec les Scopes nécessaires
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      calendar.CalendarApi.calendarEventsScope,
      calendar.CalendarApi.calendarReadonlyScope,
    ],
  );

  GoogleCalendarService._internal();

  /// Getter pour l'utilisateur actuel
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Vérifie la connexion et récupère le client API
  Future<calendar.CalendarApi?> _getCalendarApi() async {
    try {
      final account = await _ensureSignedIn();
      if (account == null) return null;

      // Utilisation de l'extension pour obtenir le client authentifié
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;

      return calendar.CalendarApi(client);
    } catch (e) {
      _log('Erreur lors de l\'initialisation de l\'API: $e');
      return null;
    }
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

  /// LOGOUT
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _log('Utilisateur déconnecté');
  }

  /// GESTION DE LA CONNEXION
  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    try {
      // 1. Tenter une connexion silencieuse (si déjà connecté auparavant)
      var user = await _googleSignIn.signInSilently();
      
      // 2. Si non connecté, ouvrir la popup Google
      user ??= await _googleSignIn.signIn();
      
      return user;
    } catch (e) {
      _log('Échec de l\'authentification Google: $e');
      return null;
    }
  }

  /// CONVERSION DES MODÈLES
  List<AgendaEvent> _convertEventsToModel(List<calendar.Event> events) {
    return events.map((e) {
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
    }).whereType<AgendaEvent>().toList();
  }

  /// Utilitaire de log propre
  void _log(String message) {
    debugPrint('[GoogleCalendarService] $message');
  }
}