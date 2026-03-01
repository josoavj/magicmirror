import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/agenda_provider.dart';
import '../../data/models/event_model.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/colors.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(agendaEventsProvider);
    final isMirror = ResponsiveHelper.isMirror(context);

    return Scaffold(
      backgroundColor: isMirror ? Colors.black : null,
      appBar: isMirror
          ? null
          : AppBar(title: const Text('Mon Agenda'), elevation: 0),
      body: eventsAsync.when(
        data: (events) => _buildContent(context, events, isMirror),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AgendaEvent> events,
    bool isMirror,
  ) {
    if (isMirror) {
      return _buildMirrorView(context, events);
    }
    return _buildMobileView(context, events);
  }

  Widget _buildMobileView(BuildContext context, List<AgendaEvent> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) => _EventTile(event: events[index]),
    );
  }

  Widget _buildMirrorView(BuildContext context, List<AgendaEvent> events) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agenda du Jour',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.resp(context, mobile: 24, mirror: 54),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 24),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 30),
              itemBuilder: (context, index) =>
                  _MirrorEventItem(event: events[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AgendaEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          '${DateFormat.Hm().format(event.startTime)} - ${DateFormat.Hm().format(event.endTime)}',
        ),
        trailing: event.location != null
            ? const Icon(Icons.location_on, size: 16)
            : null,
      ),
    );
  }
}

class _MirrorEventItem extends StatelessWidget {
  final AgendaEvent event;
  const _MirrorEventItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 25),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.Hm().format(event.startTime),
              style: const TextStyle(color: Colors.white60, fontSize: 22),
            ),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (event.location != null)
              Text(
                event.location!,
                style: const TextStyle(color: Colors.white54, fontSize: 20),
              ),
          ],
        ),
      ],
    );
  }
}
