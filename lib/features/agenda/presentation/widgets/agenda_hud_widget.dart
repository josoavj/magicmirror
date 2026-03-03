import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import '../providers/agenda_provider.dart';

class AgendaHUDWidget extends ConsumerWidget {
  const AgendaHUDWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaEventsProvider);

    return agendaState.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Prochains événements',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...events.take(3).map((event) => _buildEventItem(event)),
          ],
        );
      },
    );
  }

  Widget _buildEventItem(AgendaEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: _getTypeColor(event.eventType),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.Hm().format(event.startTime),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      'Travail' => Colors.blueAccent,
      'Routine' => Colors.greenAccent,
      'Google' => Colors.redAccent,
      _ => Colors.white30,
    };
  }
}
