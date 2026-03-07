import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import '../../../../data/services/google_calendar_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/models/event_model.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>(
  (ref) => GoogleCalendarService(),
);

final agendaEventsProvider =
    StateNotifierProvider<AgendaNotifier, AsyncValue<List<AgendaEvent>>>((ref) {
      // BUG FIX #5: Cleanup du notifier quand disposed
      final notifier = AgendaNotifier(ref.watch(googleCalendarServiceProvider));
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });

class AgendaNotifier extends StateNotifier<AsyncValue<List<AgendaEvent>>> {
  final GoogleCalendarService _service;
  Timer? _autoRefreshTimer; // BUG FIX #4: Invalidation automatique

  AgendaNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
    // Refresh automatique chaque 30 min
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      logger.debug('Auto-refresh agenda', tag: 'AgendaNotifier');
      refresh();
    });
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
      logger.error('Erreur refresh agenda', tag: 'AgendaNotifier', error: e);
      state = AsyncValue.error(e, st);
    }
  }

  // BUG FIX #5: Cleanup resources
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    logger.debug('AgendaNotifier disposed', tag: 'AgendaNotifier');
    super.dispose();
  }

  Future<void> syncWithGoogle() async {
    final success = await _service.signIn();
    if (success) {
      await refresh();
    }
  }
}
