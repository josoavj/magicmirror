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
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
    });
    await ref.read(agendaEventsProvider.notifier).refresh(_selectedDay);
  }

  Future<void> _showEventDialog({AgendaEvent? editingEvent}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents closing while saving
      builder: (dialogContext) => _AgendaEventDialog(
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
                          tooltip: Localizations.localeOf(context).languageCode == 'en' ? 'Select day' : 'Choisir un jour',
                        ),
                        const SizedBox(width: 10),
                        _GlassIconButton(
                          icon: Icons.refresh,
                          onPressed: () => ref
                              .read(agendaEventsProvider.notifier)
                              .refresh(_selectedDay, true),
                          tooltip: Localizations.localeOf(context).languageCode == 'en' ? 'Refresh' : 'Actualiser',
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
                      '${_tr(context, 'Erreur', 'Error')}: $err',
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
                        label: _tr(context, 'Retour', 'Back'),
                        onPressed: () {
                          // Clean up before navigating
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          );
                        },
                        icon: Icons.arrow_back_ios_new,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GlassButton(
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

class _AgendaEventDialog extends ConsumerStatefulWidget {
  final AgendaEvent? editingEvent;
  final DateTime selectedDay;

  const _AgendaEventDialog({
    super.key,
    this.editingEvent,
    required this.selectedDay,
  });

  @override
  ConsumerState<_AgendaEventDialog> createState() => _AgendaEventDialogState();
}

class _AgendaEventDialogState extends ConsumerState<_AgendaEventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late DateTime _startTime;
  late DateTime _endTime;
  late String _eventType;

  final _formKey = GlobalKey<FormState>();
  final _eventTypes = <String>['Personnel', 'Travail', 'Routine', 'Autre'];
  bool _isSaving = false;

  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.editingEvent?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.editingEvent?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.editingEvent?.location ?? '',
    );

    _startTime =
        widget.editingEvent?.startTime ??
        DateTime(
          widget.selectedDay.year,
          widget.selectedDay.month,
          widget.selectedDay.day,
          9,
          0,
        );
    _endTime =
        widget.editingEvent?.endTime ?? _startTime.add(const Duration(hours: 1));
    _eventType = widget.editingEvent?.eventType ?? 'Personnel';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool forStart}) async {
    final source = forStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: source,
      firstDate: DateTime(widget.selectedDay.year - 1),
      lastDate: DateTime(widget.selectedDay.year + 2),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
    );
    if (time == null || !mounted) {
      return;
    }
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (forStart) {
        _startTime = value;
        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.editingEvent == null
            ? _tr(context, 'Nouvel événement', 'New event')
            : _tr(context, 'Modifier événement', 'Edit event'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Titre obligatoire';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 1,
                maxLines: 3,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lieu'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _eventType,
                items: _eventTypes
                    .map(
                      (item) => DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _eventType = value;
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
                      onPressed: () => _pickDateTime(forStart: true),
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        'Début\n${_startTime.day.toString().padLeft(2, '0')}/${_startTime.month.toString().padLeft(2, '0')} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(forStart: false),
                      icon: const Icon(Icons.schedule_send),
                      label: Text(
                        'Fin\n${_endTime.day.toString().padLeft(2, '0')}/${_endTime.month.toString().padLeft(2, '0')} ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(_tr(context, 'Annuler', 'Cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  if (!_endTime.isAfter(_startTime)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _tr(
                              context,
                              'La fin doit être après le début.',
                              'End must be after start.',
                            ),
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  setState(() => _isSaving = true);

                  try {
                    final notifier = ref.read(agendaEventsProvider.notifier);
                    final title = _titleController.text.trim();
                    final desc = _descriptionController.text.trim();
                    final loc = _locationController.text.trim();

                    if (widget.editingEvent == null) {
                      await notifier.createEvent(
                        title: title,
                        description: desc.isEmpty ? null : desc,
                        startTime: _startTime,
                        endTime: _endTime,
                        location: loc.isEmpty ? null : loc,
                        eventType: _eventType,
                      );
                    } else {
                      await notifier.updateEvent(
                        widget.editingEvent!.copyWith(
                          title: title,
                          description: desc.isEmpty ? null : desc,
                          startTime: _startTime,
                          endTime: _endTime,
                          location: loc.isEmpty ? null : loc,
                          eventType: _eventType,
                        ),
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_tr(context, 'Enregistrer', 'Save')),
        ),
      ],
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
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final accentColor = isNow ? Colors.cyanAccent : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        blur: isNow ? 40 : 32,
        opacity: isNow ? 0.16 : 0.1,
        tintColor: isNow ? Colors.cyan.withValues(alpha: 0.8) : Colors.white,
        borderWidth: isNow ? 2.0 : 1.1,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNow)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sensors,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEnglish ? 'NOW' : 'EN CE MOMENT',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.62),
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
                      fontWeight:
                          isNow ? FontWeight.bold : FontWeight.w500,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleComplete,
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCompleted
                        ? Colors.greenAccent
                        : (isNow ? Colors.cyanAccent : Colors.white70),
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
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(isEnglish ? 'Edit' : 'Modifier'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(isEnglish ? 'Delete' : 'Supprimer'),
                    ),
                  ],
                ),
                if (isNow)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.cyanAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent,
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
              ],
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
  final String? tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

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
        tooltip: tooltip,
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
