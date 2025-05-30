class Mentorship {
  final String id;
  final String mentorId;
  final String menteeId;
  final String? assignedBy; // Added 5/29/25
  final double overallProgress; // Added 5/29/25
  final DateTime createdAt;

  Mentorship({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    this.assignedBy,
    this.overallProgress = 0.0,
    required this.createdAt,
  });

  factory Mentorship.fromMap(Map<String, dynamic> map) {
    return Mentorship(
      id: map['id'],
      mentorId: map['mentor_id'],
      menteeId: map['mentee_id'],
      assignedBy: map['assigned_by'],
      overallProgress: map['overall_progress'] ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'assigned_by': assignedBy,
      'overall_progress': overallProgress,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}