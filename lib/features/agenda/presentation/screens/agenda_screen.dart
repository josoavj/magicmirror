import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import '../providers/agenda_provider.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _selectedDay = DateTime.now();

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
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
    });
    await ref.read(agendaEventsProvider.notifier).refresh(_selectedDay);
  }

  Future<void> _showEventDialog({AgendaEvent? editingEvent}) async {
    final titleController = TextEditingController(
      text: editingEvent?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: editingEvent?.description ?? '',
    );
    final locationController = TextEditingController(
      text: editingEvent?.location ?? '',
    );

    DateTime startTime =
        editingEvent?.startTime ??
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 9, 0);
    DateTime endTime =
        editingEvent?.endTime ?? startTime.add(const Duration(hours: 1));
    String eventType = editingEvent?.eventType ?? 'Personnel';

    final formKey = GlobalKey<FormState>();
    final eventTypes = <String>['Personnel', 'Travail', 'Routine', 'Autre'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            Future<void> pickDateTime({required bool forStart}) async {
              final source = forStart ? startTime : endTime;
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: source,
                firstDate: DateTime(_selectedDay.year - 1),
                lastDate: DateTime(_selectedDay.year + 2),
              );
              if (date == null || !dialogContext.mounted) {
                return;
              }
              final time = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(source),
              );
              if (time == null || !dialogContext.mounted) {
                return;
              }
              final value = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              setLocalState(() {
                if (forStart) {
                  startTime = value;
                  if (!endTime.isAfter(startTime)) {
                    endTime = startTime.add(const Duration(hours: 1));
                  }
                } else {
                  endTime = value;
                }
              });
            }

            return AlertDialog(
              title: Text(
                editingEvent == null
                    ? 'Nouvel évènement'
                    : 'Modifier évènement',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Titre'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Titre obligatoire';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Lieu'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: eventType,
                        items: eventTypes
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setLocalState(() {
                              eventType = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDateTime(forStart: true),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                'Début\n${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDateTime(forStart: false),
                              icon: const Icon(Icons.schedule_send),
                              label: Text(
                                'Fin\n${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    if (!endTime.isAfter(startTime)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('La fin doit être après le début.'),
                        ),
                      );
                      return;
                    }

                    final notifier = ref.read(agendaEventsProvider.notifier);
                    if (editingEvent == null) {
                      await notifier.createEvent(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        startTime: startTime,
                        endTime: endTime,
                        location: locationController.text.trim().isEmpty
                            ? null
                            : locationController.text.trim(),
                        eventType: eventType,
                      );
                    } else {
                      await notifier.updateEvent(
                        editingEvent.copyWith(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          startTime: startTime,
                          endTime: endTime,
                          location: locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          eventType: eventType,
                        ),
                      );
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
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
                          'Planning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 30 : 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _GlassIconButton(
                          icon: Icons.event,
                          onPressed: _pickDay,
                        ),
                        const SizedBox(width: 10),
                        _GlassIconButton(
                          icon: Icons.refresh,
                          onPressed: () => ref
                              .read(agendaEventsProvider.notifier)
                              .refresh(_selectedDay),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: agendaState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Erreur: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (events) => ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final now = DateTime.now();
                      final isNow =
                          now.isAfter(event.startTime) &&
                          now.isBefore(event.endTime);

                      return _AgendaGlassTile(
                        time:
                            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                        title: event.title,
                        type: event.eventType,
                        isNow: isNow,
                        isCompleted: event.isCompleted,
                        onEdit: () => _showEventDialog(editingEvent: event),
                        onDelete: () async {
                          await ref
                              .read(agendaEventsProvider.notifier)
                              .deleteEvent(event.id);
                        },
                        onToggleComplete: () async {
                          await ref
                              .read(agendaEventsProvider.notifier)
                              .toggleComplete(event);
                        },
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
                      child: _GlassButton(
                        label: 'Retour',
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        ),
                        icon: Icons.arrow_back_ios_new,
                      ),
                    ),

                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: _GlassButton(
                        label: 'Ajouter',
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

class _AgendaGlassTile extends StatelessWidget {
  final String time;
  final String title;
  final String type;
  final bool isNow;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _AgendaGlassTile({
    required this.time,
    required this.title,
    required this.type,
    this.isNow = false,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        blur: isNow ? 36 : 32,
        opacity: isNow ? 0.13 : 0.1,
        tintColor: isNow ? Colors.blue : Colors.white,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(width: isMobile ? 16 : 24),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isCompleted
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w500,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            IconButton(
              onPressed: onToggleComplete,
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.greenAccent : Colors.white70,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
            if (isNow)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 16,
      opacity: 0.12,
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _GlassButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: 24,
        blur: 28,
        opacity: 0.11,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 20),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
