import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';

class AgendaEventDialog extends ConsumerStatefulWidget {
  final AgendaEvent? editingEvent;
  final DateTime selectedDay;

  const AgendaEventDialog({
    super.key,
    this.editingEvent,
    required this.selectedDay,
  });

  @override
  ConsumerState<AgendaEventDialog> createState() => _AgendaEventDialogState();
}

class _AgendaEventDialogState extends ConsumerState<AgendaEventDialog> {
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
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
    );
    if (time == null || !mounted) return;
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
                initialValue: _eventType,
                items: _eventTypes
                    .map(
                      (item) => DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _eventType = value);
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
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  if (!_endTime.isAfter(_startTime)) {
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
                    return;
                  }

                  setState(() => _isSaving = true);
                  try {
                    final notifier = ref.read(agendaEventsProvider.notifier);
                    if (widget.editingEvent == null) {
                      await notifier.createEvent(
                        title: _titleController.text.trim(),
                        description: _descriptionController.text.trim(),
                        startTime: _startTime,
                        endTime: _endTime,
                        location: _locationController.text.trim(),
                        eventType: _eventType,
                      );
                    } else {
                      await notifier.updateEvent(
                        widget.editingEvent!.copyWith(
                          title: _titleController.text.trim(),
                          description: _descriptionController.text.trim(),
                          startTime: _startTime,
                          endTime: _endTime,
                          location: _locationController.text.trim(),
                          eventType: _eventType,
                        ),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => _isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
          child: _isSaving
              ? const CircularProgressIndicator()
              : Text(_tr(context, 'Enregistrer', 'Save')),
        ),
      ],
    );
  }
}
