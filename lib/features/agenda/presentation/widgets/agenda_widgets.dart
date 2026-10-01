import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';

class AgendaGlassTile extends StatelessWidget {
  final AgendaEvent event;
  final bool isNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const AgendaGlassTile({
    super.key,
    required this.event,
    this.isNow = false,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final locale = Localizations.localeOf(context).toString();
    final colors = Theme.of(context).colorScheme;
    final startTime = DateFormat.Hm(locale).format(event.startTime);
    final endTime = DateFormat.Hm(locale).format(event.endTime);
    final date = formatDisplayDate(
      event.startTime,
      locale: locale,
      includeYear: false,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: IconButton(
            tooltip: event.isCompleted
                ? (isEnglish ? 'Mark as pending' : 'Marquer comme à faire')
                : (isEnglish ? 'Mark as completed' : 'Marquer comme terminé'),
            onPressed: onToggleComplete,
            icon: Icon(
              event.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: event.isCompleted
                  ? Colors.greenAccent
                  : (isNow ? Colors.cyanAccent : Colors.white70),
            ),
          ),
          title: Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: event.isCompleted ? Colors.white54 : Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: isNow ? FontWeight.bold : FontWeight.w600,
              decoration: event.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${isNow ? '${isEnglish ? 'NOW' : 'EN CE MOMENT'} · ' : ''}$startTime – $endTime · ${event.eventType}',
            style: TextStyle(
              color: isNow ? Colors.cyanAccent : Colors.white70,
              fontSize: 13,
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 20,
            0,
            isMobile ? 16 : 20,
            16,
          ),
          children: [
            _AgendaDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: date,
            ),
            _AgendaDetailRow(
              icon: Icons.schedule_rounded,
              label: isEnglish ? 'Time' : 'Horaire',
              value: '$startTime – $endTime',
            ),
            _AgendaDetailRow(
              icon: Icons.category_outlined,
              label: 'Type',
              value: event.eventType,
            ),
            if (event.location?.trim().isNotEmpty ?? false)
              _AgendaDetailRow(
                icon: Icons.place_outlined,
                label: isEnglish ? 'Location' : 'Lieu',
                value: event.location!.trim(),
              ),
            if (event.description?.trim().isNotEmpty ?? false)
              _AgendaDetailRow(
                icon: Icons.notes_rounded,
                label: isEnglish ? 'Description' : 'Description',
                value: event.description!.trim(),
              ),
            _AgendaDetailRow(
              icon: event.isCompleted
                  ? Icons.task_alt_rounded
                  : Icons.pending_actions_rounded,
              label: isEnglish ? 'Status' : 'État',
              value: event.isCompleted
                  ? (isEnglish ? 'Completed' : 'Terminé')
                  : (isEnglish ? 'To do' : 'À faire'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(isEnglish ? 'Edit' : 'Modifier'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(isEnglish ? 'Delete' : 'Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AgendaDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
