class Meeting {
  final String id;
  final String mentorId;
  final String menteeId;
  final String startTime;
  final String? endTime;
  final String? topic;
  final String? location; // Added 5/29/25
  final String status;
  final String? availabilityId;
  final bool synced;
  final DateTime? createdAt;

  Meeting({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.startTime,
    this.endTime,
    this.topic,
    this.location,
    this.status = 'pending',
    this.availabilityId,
    this.synced = false,
    this.createdAt,
  });

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'],
      mentorId: map['mentor_id'],
      menteeId: map['mentee_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      topic: map['topic'],
      location: map['location'],
      status: map['status'] ?? 'pending',
      availabilityId: map['availability_id'],
      synced: map['synced'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'start_time': startTime,
      'end_time': endTime,
      'topic': topic,
      'location': location,
      'status': status,
      'availability_id': availabilityId,
      'synced': synced ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch,
    };
  }

  Meeting copyWith({
    String? id,
    String? mentorId,
    String? menteeId,
    String? startTime,
    String? endTime,
    String? topic,
    String? location,
    String? status,
    String? availabilityId,
    bool? synced,
    DateTime? createdAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      menteeId: menteeId ?? this.menteeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      topic: topic ?? this.topic,
      location: location ?? this.location,
      status: status ?? this.status,
      availabilityId: availabilityId ?? this.availabilityId,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}