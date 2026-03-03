import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../data/services/google_calendar_service.dart';
import '../../data/models/event_model.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) => GoogleCalendarService());

final agendaEventsProvider = StateNotifierProvider<AgendaNotifier, AsyncValue<List<AgendaEvent>>>((ref) {
  return AgendaNotifier(ref.watch(googleCalendarServiceProvider));
});

class AgendaNotifier extends StateNotifier<AsyncValue<List<AgendaEvent>>> {
  final GoogleCalendarService _service;

  AgendaNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final events = await _service.getTodayEvents();
      if (events.isEmpty) {
        state = AsyncValue.data([
          AgendaEvent(
            id: '1',
            title: 'Réveil & Méditation',
            startTime: DateTime.now().copyWith(hour: 7, minute: 0),
            endTime: DateTime.now().copyWith(hour: 7, minute: 30),
            eventType: 'Routine',
          ),
          AgendaEvent(
            id: '2',
            title: 'Préparation Journée',
            startTime: DateTime.now().copyWith(hour: 8, minute: 0),
            endTime: DateTime.now().copyWith(hour: 9, minute: 0),
            eventType: 'Travail',
          ),
        ]);
      } else {
        state = AsyncValue.data(events);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncWithGoogle() async {
    final success = await _service.signIn();
    if (success) {
      await refresh();
    }
  }
}
