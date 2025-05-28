class Mentorship {
  final String id;
  final String mentorId;
  final String menteeId;
  final DateTime createdAt;

  Mentorship({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.createdAt,
  });

  factory Mentorship.fromMap(Map<String, dynamic> map) {
    return Mentorship(
      id: map['id'],
      mentorId: map['mentor_id'],
      menteeId: map['mentee_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}