import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/presentation/widgets/glass_dialog.dart';

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
        widget.editingEvent?.endTime ??
        _startTime.add(const Duration(hours: 1));
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
      builder: glassDialogBuilder,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
      builder: glassDialogBuilder,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _tr(context, 'Titre', 'Title'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _tr(
                      context,
                      'Veuillez renseigner le titre de l’événement.',
                      'Please enter an event title.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: _tr(context, 'Description', 'Description'),
                  alignLabelWithHint: true,
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: _tr(context, 'Lieu', 'Location'),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _eventType,
                items: _eventTypes
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _eventType = value);
                },
                decoration: InputDecoration(
                  labelText: _tr(context, 'Type', 'Type'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _tr(context, 'Date et horaires', 'Date and time'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDateTime(forStart: true),
                      child: _DateTimeButtonLabel(
                        icon: Icons.schedule_rounded,
                        title: _tr(context, 'Début', 'Start'),
                        dateTime: formatDisplayDateTime(
                          _startTime,
                          locale: Localizations.localeOf(context).toString(),
                          includeYear: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDateTime(forStart: false),
                      child: _DateTimeButtonLabel(
                        icon: Icons.schedule_send_rounded,
                        title: _tr(context, 'Fin', 'End'),
                        dateTime: formatDisplayDateTime(
                          _endTime,
                          locale: Localizations.localeOf(context).toString(),
                          includeYear: false,
                        ),
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
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1.2,
            ),
          ),
          child: Text(_tr(context, 'Annuler', 'Cancel')),
        ),
        FilledButton(
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
                        SnackBar(
                          content: Text(
                            _tr(
                              context,
                              'L’événement n’a pas pu être enregistré. Veuillez réessayer.',
                              'The event could not be saved. Please try again.',
                            ),
                          ),
                        ),
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

class _DateTimeButtonLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String dateTime;

  const _DateTimeButtonLabel({
    required this.icon,
    required this.title,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateTime,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
