class Event {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime? endTime;
  final String createdBy;
  final String? eventType;
  final String? targetAudience;
  final int? maxParticipants;
  final bool requiredRegistration;
  final bool synced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    this.endTime,
    required this.createdBy,
    this.eventType,
    this.targetAudience,
    this.maxParticipants,
    this.requiredRegistration = false,
    this.synced = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      createdBy: map['created_by'],
      eventType: map['event_type'],
      targetAudience: map['target_audience'],
      maxParticipants: map['max_participants'],
      requiredRegistration: map['required_registration'] == 1,
      synced: map['synced'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'created_by': createdBy,
      'event_type': eventType,
      'target_audience': targetAudience,
      'max_participants': maxParticipants,
      'required_registration': requiredRegistration ? 1 : 0,
      'synced': synced ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }
}