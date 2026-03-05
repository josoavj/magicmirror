import '../../features/agenda/data/models/event_model.dart';

/// Service de calendrier mocké pour le développement
class MockCalendarService {
  static final MockCalendarService _instance = MockCalendarService._internal();

  factory MockCalendarService() => _instance;

  MockCalendarService._internal();

  /// Retourne les événements d'aujourd'hui (mockés)
  Future<List<AgendaEvent>> getTodayEvents() async {
    // Simuler une requête API
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    return [
      AgendaEvent(
        id: '1',
        title: 'Réveil & Méditation',
        startTime: now.copyWith(
          hour: 7,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 7,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Commencer la journée avec sérénité',
        eventType: 'Routine',
      ),
      AgendaEvent(
        id: '2',
        title: 'Petit-déjeuner',
        startTime: now.copyWith(
          hour: 7,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 8,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Petit-déjeuner sain et équilibré',
        eventType: 'Repas',
      ),
      AgendaEvent(
        id: '3',
        title: 'Réunion de projet',
        startTime: now.copyWith(
          hour: 9,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 10,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Synchronisation avec l\'équipe',
        location: 'Salle de réunion A',
        eventType: 'Travail',
      ),
      AgendaEvent(
        id: '4',
        title: 'Pause déjeuner',
        startTime: now.copyWith(
          hour: 12,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 13,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Repas de midi',
        location: 'Café du coin',
        eventType: 'Repas',
      ),
      AgendaEvent(
        id: '5',
        title: 'Séance de sport',
        startTime: now.copyWith(
          hour: 17,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 18,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Session de fitness',
        location: 'Salle de sport',
        eventType: 'Personnel',
      ),
      AgendaEvent(
        id: '6',
        title: 'Dîner en famille',
        startTime: now.copyWith(
          hour: 19,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        endTime: now.copyWith(
          hour: 20,
          minute: 30,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        description: 'Repas du soir avec la famille',
        location: 'À la maison',
        eventType: 'Personnel',
      ),
    ];
  }

  /// Retourne les événements à venir (mockés)
  Future<List<AgendaEvent>> getUpcomingEvents({int maxResults = 20}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await getTodayEvents();
  }
}
