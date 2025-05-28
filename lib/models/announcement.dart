class Announcement {
  final String id;
  final String title;
  final String content;
  final String time;
  final String? priority;
  final String? targetAudience;
  final DateTime createdAt;
  final String? createdBy;
  final bool synced;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.priority,
    this.targetAudience,
    required this.createdAt,
    this.createdBy,
    this.synced = false,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      time: map['time'],
      priority: map['priority'],
      targetAudience: map['target_audience'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      createdBy: map['created_by'],
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'time': time,
      'priority': priority,
      'target_audience': targetAudience,
      'created_at': createdAt.millisecondsSinceEpoch,
      'created_by': createdBy,
      'synced': synced ? 1 : 0,
    };
  }
}