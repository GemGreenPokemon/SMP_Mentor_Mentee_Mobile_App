// Model class for notifications - Added 5/29/25
class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'meeting', 'report', 'announcement', 'task'
  final String? priority; // 'high', 'medium', 'low'
  final bool read;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority,
    this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'read': read ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      priority: map['priority'],
      read: map['read'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? read,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Notification{id: $id, userId: $userId, title: $title, type: $type, read: $read}';
  }
}