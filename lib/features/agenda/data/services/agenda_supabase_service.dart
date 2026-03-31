import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendaSupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Utilisateur non connecte');
    }
    return userId;
  }

  Future<List<AgendaEvent>> fetchEventsForDay(DateTime day) async {
    final userId = _requireUserId();
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await _client
        .from('agenda_events')
        .select()
        .eq('user_id', userId)
        .gte('start_time', start.toUtc().toIso8601String())
        .lt('start_time', end.toUtc().toIso8601String())
        .order('start_time', ascending: true);

    return (rows as List<dynamic>)
        .map((item) => AgendaEvent.fromSupabase(item as Map<String, dynamic>))
        .toList();
  }

  Future<AgendaEvent> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String eventType = 'Other',
  }) async {
    final userId = _requireUserId();
    final payload = {
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'location': location,
      'event_type': eventType,
      'is_completed': false,
    };

    final row = await _client
        .from('agenda_events')
        .insert(payload)
        .select()
        .single();

    return AgendaEvent.fromSupabase(row);
  }

  Future<void> updateEvent(AgendaEvent event) async {
    final userId = _requireUserId();
    await _client
        .from('agenda_events')
        .update({
          'title': event.title,
          'description': event.description,
          'start_time': event.startTime.toUtc().toIso8601String(),
          'end_time': event.endTime.toUtc().toIso8601String(),
          'location': event.location,
          'event_type': event.eventType,
          'is_completed': event.isCompleted,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', event.id)
        .eq('user_id', userId);
  }

  Future<void> deleteEvent(String eventId) async {
    final userId = _requireUserId();
    await _client
        .from('agenda_events')
        .delete()
        .eq('id', eventId)
        .eq('user_id', userId);
  }
}
