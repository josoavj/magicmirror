import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:magicmirror/core/utils/responsive_helper.dart';
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
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'Prochains événements',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: ResponsiveHelper.resp(
                    context,
                    mobile: 12,
                    tablet: 14,
                  ),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...events.take(3).map((event) => _EventItemWidget(event: event)),
          ],
        );
      },
    );
  }
}

class _EventItemWidget extends StatelessWidget {
  final AgendaEvent event;

  const _EventItemWidget({required this.event});

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.resp(
                      context,
                      mobile: 13,
                      tablet: 15,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.Hm().format(event.startTime),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: ResponsiveHelper.resp(
                      context,
                      mobile: 11,
                      tablet: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _getTypeColor(String type) {
  return switch (type) {
    'Travail' => Colors.blueAccent,
    'Routine' => Colors.greenAccent,
    'Personnel' => Colors.purpleAccent,
    'Autre' => Colors.orangeAccent,
    _ => Colors.white30,
  };
}
