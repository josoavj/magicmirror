import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/agenda/presentation/widgets/agenda_event_dialog.dart';
import 'package:magicmirror/features/agenda/presentation/widgets/agenda_widgets.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _selectedDay = DateTime.now();

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agendaEventsProvider.notifier).refresh(_selectedDay);
    });
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null) return;
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
    });
    await ref.read(agendaEventsProvider.notifier).refresh(_selectedDay);
  }

  Future<void> _showEventDialog({dynamic editingEvent}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AgendaEventDialog(
        editingEvent: editingEvent,
        selectedDay: _selectedDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaEventsProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr(context, 'Planning', 'Schedule'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 30 : 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: isMobile ? 16 : 18,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AgendaGlassIconButton(
                          icon: Icons.event,
                          onPressed: _pickDay,
                        ),
                        const SizedBox(width: 10),
                        AgendaGlassIconButton(
                          icon: Icons.refresh,
                          onPressed: () => ref
                              .read(agendaEventsProvider.notifier)
                              .refresh(_selectedDay, true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: agendaState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur: $err')),
                  data: (events) => ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final now = DateTime.now();
                      final isNow = now.isAfter(event.startTime) && now.isBefore(event.endTime);

                      return AgendaGlassTile(
                        time: '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                        title: event.title,
                        type: event.eventType,
                        isNow: isNow,
                        isCompleted: event.isCompleted,
                        onEdit: () => _showEventDialog(editingEvent: event),
                        onDelete: () => ref.read(agendaEventsProvider.notifier).deleteEvent(event.id),
                        onToggleComplete: () => ref.read(agendaEventsProvider.notifier).toggleComplete(event),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Row(
                  children: [
                    Expanded(
                      child: AgendaGlassButton(
                        label: _tr(context, 'Retour', 'Back'),
                        onPressed: () => Navigator.pop(context),
                        icon: Icons.arrow_back,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AgendaGlassButton(
                        label: _tr(context, 'Ajouter', 'Add'),
                        onPressed: _showEventDialog,
                        icon: Icons.add,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
