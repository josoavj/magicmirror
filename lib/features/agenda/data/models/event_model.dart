class AgendaEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String eventType; // e.g., 'Work', 'Personal', 'Other'
  final bool isCompleted;

  AgendaEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.eventType = 'Other',
    this.isCompleted = false,
  });

  AgendaEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? eventType,
    bool? isCompleted,
  }) {
    return AgendaEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory AgendaEvent.fromSupabase(Map<String, dynamic> json) {
    return AgendaEvent(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? 'Sans titre').toString(),
      description: json['description']?.toString(),
      startTime: DateTime.parse(
        (json['start_time'] ?? '').toString(),
      ).toLocal(),
      endTime: DateTime.parse((json['end_time'] ?? '').toString()).toLocal(),
      location: json['location']?.toString(),
      eventType: (json['event_type'] ?? 'Other').toString(),
      isCompleted: json['is_completed'] == true,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'location': location,
      'event_type': eventType,
      'is_completed': isCompleted,
    };
  }
}
