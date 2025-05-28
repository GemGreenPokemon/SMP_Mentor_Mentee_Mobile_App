class Availability {
  final String id;
  final String mentorId;
  final String day;
  final String slotStart;
  final String? slotEnd;
  final bool isBooked;
  final String? menteeId;
  final bool synced;
  final DateTime? updatedAt;

  Availability({
    required this.id,
    required this.mentorId,
    required this.day,
    required this.slotStart,
    this.slotEnd,
    this.isBooked = false,
    this.menteeId,
    this.synced = false,
    this.updatedAt,
  });

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      id: map['id'],
      mentorId: map['mentor_id'],
      day: map['day'],
      slotStart: map['slot_start'],
      slotEnd: map['slot_end'],
      isBooked: map['is_booked'] == 1,
      menteeId: map['mentee_id'],
      synced: map['synced'] == 1,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'day': day,
      'slot_start': slotStart,
      'slot_end': slotEnd,
      'is_booked': isBooked ? 1 : 0,
      'mentee_id': menteeId,
      'synced': synced ? 1 : 0,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  Availability copyWith({
    String? id,
    String? mentorId,
    String? day,
    String? slotStart,
    String? slotEnd,
    bool? isBooked,
    String? menteeId,
    bool? synced,
    DateTime? updatedAt,
  }) {
    return Availability(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      day: day ?? this.day,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      isBooked: isBooked ?? this.isBooked,
      menteeId: menteeId ?? this.menteeId,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}