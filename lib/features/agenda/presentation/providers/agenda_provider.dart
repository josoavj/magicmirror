import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import '../../../../core/utils/app_logger.dart';
import '../../data/models/event_model.dart';
import '../../data/services/agenda_supabase_service.dart';

final agendaSupabaseServiceProvider = Provider<AgendaSupabaseService>(
  (ref) => AgendaSupabaseService(),
);

final agendaEventsProvider =
    StateNotifierProvider<AgendaNotifier, AsyncValue<List<AgendaEvent>>>((ref) {
      final notifier = AgendaNotifier(ref.watch(agendaSupabaseServiceProvider));
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });

class AgendaNotifier extends StateNotifier<AsyncValue<List<AgendaEvent>>> {
  final AgendaSupabaseService _service;
  Timer? _autoRefreshTimer;
  DateTime _selectedDay = DateTime.now();

  AgendaNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      logger.debug('Auto-refresh agenda', tag: 'AgendaNotifier');
      refresh(null, true);
    });
  }

  DateTime get selectedDay => _selectedDay;

  Future<void> refresh([DateTime? day, bool silent = false]) async {
    if (day != null) {
      _selectedDay = DateTime(day.year, day.month, day.day);
    }
    
    if (!silent) {
      state = const AsyncValue.loading();
    }
    
    try {
      final events = await _service.fetchEventsForDay(_selectedDay);
      state = AsyncValue.data(events);
    } catch (e, st) {
      logger.error('Erreur refresh agenda', tag: 'AgendaNotifier', error: e);
      if (!silent) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String eventType = 'Other',
  }) async {
    try {
      await _service.createEvent(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        eventType: eventType,
      );
      await refresh();
    } catch (e, st) {
      logger.error(
        'Erreur création événement',
        tag: 'AgendaNotifier',
        error: e,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEvent(AgendaEvent event) async {
    try {
      await _service.updateEvent(event);
      await refresh();
    } catch (e, st) {
      logger.error(
        'Erreur mise à jour événement',
        tag: 'AgendaNotifier',
        error: e,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _service.deleteEvent(eventId);
      await refresh(null, true);
    } catch (e, st) {
      logger.error(
        'Erreur suppression événement',
        tag: 'AgendaNotifier',
        error: e,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleComplete(AgendaEvent event) async {
    final oldState = state;
    if (state is AsyncData<List<AgendaEvent>>) {
      final currentList = state.asData!.value;
      final newList = currentList.map((e) {
        if (e.id == event.id) {
          return e.copyWith(isCompleted: !event.isCompleted);
        }
        return e;
      }).toList();
      state = AsyncValue.data(newList);
    }

    try {
      await _service.updateEvent(event.copyWith(isCompleted: !event.isCompleted));
      // Pas besoin de refresh complet ici si on fait confiance à l'optimisme,
      // mais on peut faire un refresh silencieux pour confirmer.
      await refresh(null, true);
    } catch (e) {
      logger.error('Erreur toggle complete', tag: 'AgendaNotifier', error: e);
      state = oldState; // Rollback en cas d'erreur
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    logger.debug('AgendaNotifier disposed', tag: 'AgendaNotifier');
    super.dispose();
  }
}
