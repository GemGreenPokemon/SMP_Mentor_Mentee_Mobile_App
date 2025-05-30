// Model class for mentee goals - Added 5/29/25
class MenteeGoal {
  final String id;
  final String mentorshipId;
  final String title;
  final double progress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenteeGoal({
    required this.id,
    required this.mentorshipId,
    required this.title,
    this.progress = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorship_id': mentorshipId,
      'title': title,
      'progress': progress,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory MenteeGoal.fromMap(Map<String, dynamic> map) {
    return MenteeGoal(
      id: map['id'],
      mentorshipId: map['mentorship_id'],
      title: map['title'],
      progress: map['progress'] ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  MenteeGoal copyWith({
    String? id,
    String? mentorshipId,
    String? title,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenteeGoal(
      id: id ?? this.id,
      mentorshipId: mentorshipId ?? this.mentorshipId,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MenteeGoal{id: $id, mentorshipId: $mentorshipId, title: $title, progress: $progress}';
  }
}