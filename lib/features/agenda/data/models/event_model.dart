class AgendaEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String eventType; // e.g., 'Work', 'Personal', 'Other'
  final bool isCompleted;

  AgendaEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.eventType = 'Other',
    this.isCompleted = false,
  });
}
