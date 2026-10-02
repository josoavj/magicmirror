import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/agenda/presentation/widgets/agenda_event_dialog.dart';
import 'package:magicmirror/features/agenda/presentation/widgets/agenda_widgets.dart';
import 'package:magicmirror/presentation/widgets/glass_dialog.dart';

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
      builder: glassDialogBuilder,
    );
    if (selected == null) return;
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
    });
    await ref.read(agendaEventsProvider.notifier).refresh(_selectedDay);
  }

  Future<void> _showEventDialog({dynamic editingEvent}) async {
    await showGlassDialog<void>(
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
    final locale = Localizations.localeOf(context).toString();
    final formattedDay = formatDisplayDate(
      _selectedDay,
      locale: locale,
      includeYear: false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(_tr(context, 'Agenda', 'Calendar')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: _tr(context, 'Retour', 'Back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            tooltip: _tr(context, 'Choisir une date', 'Choose a date'),
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: _tr(context, 'Actualiser', 'Refresh'),
            onPressed: () => ref
                .read(agendaEventsProvider.notifier)
                .refresh(_selectedDay, true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEventDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tr(context, 'Ajouter', 'Add')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 24,
                  16,
                  isMobile ? 18 : 24,
                  12,
                ),
                child: Text(
                  '${_tr(context, 'Planning du', 'Schedule for')} $formattedDay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: agendaState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      userFacingError(
                        context,
                        err,
                        frenchFallback:
                            'Votre agenda n’a pas pu être chargé. Veuillez réessayer.',
                        englishFallback:
                            'Your calendar could not be loaded. Please try again.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (events) => ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      0,
                      isMobile ? 16 : 24,
                      96,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final now = DateTime.now();
                      final isNow =
                          now.isAfter(event.startTime) &&
                          now.isBefore(event.endTime);

                      return AgendaGlassTile(
                        event: event,
                        isNow: isNow,
                        onEdit: () => _showEventDialog(editingEvent: event),
                        onDelete: () => ref
                            .read(agendaEventsProvider.notifier)
                            .deleteEvent(event.id),
                        onToggleComplete: () => ref
                            .read(agendaEventsProvider.notifier)
                            .toggleComplete(event),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
