import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../../features/agenda/data/models/event_model.dart';
import 'package:uuid/uuid.dart';

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: [
      calendar.CalendarApi.calendarReadonlyScope,
    ],
  );

  Future<List<AgendaEvent>> getUpcomingEvents() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return [];

      final client = await account.authenticatedClient();
      if (client == null) return [];

      final calendarApi = calendar.CalendarApi(client);
      final now = DateTime.now().toUtc();
      
      final events = await calendarApi.events.list(
        'primary',
        timeMin: now,
        maxResults: 10,
        orderBy: 'startTime',
        singleEvents: true,
      );

      final uuid = const Uuid();

      return events.items?.map((e) {
        final start = (e.start?.dateTime ?? e.start?.date ?? DateTime.now()).toLocal();
        final end = (e.end?.dateTime ?? e.end?.date ?? start.add(const Duration(hours: 1))).toLocal();
        return AgendaEvent(
          id: e.id ?? uuid.v4(),
          title: e.summary ?? 'Sans titre',
          description: e.description,
          startTime: start,
          endTime: end,
          location: e.location,
          eventType: 'Google',
        );
      }).toList() ?? [];
    } catch (e) {
      _debugPrint('Erreur Google Calendar: $e');
      return [];
    }
  }

  void _debugPrint(String message) {
    // ignore: avoid_print
    print('[GoogleCalendarService] $message');
  }
}
