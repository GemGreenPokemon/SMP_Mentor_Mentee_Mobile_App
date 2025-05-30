// Model class for action items - Added 5/29/25
class ActionItem {
  final String id;
  final String mentorshipId;
  final String task;
  final String? description;
  final String? dueDate;
  final bool completed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ActionItem({
    required this.id,
    required this.mentorshipId,
    required this.task,
    this.description,
    this.dueDate,
    this.completed = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorship_id': mentorshipId,
      'task': task,
      'description': description,
      'due_date': dueDate,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      id: map['id'],
      mentorshipId: map['mentorship_id'],
      task: map['task'],
      description: map['description'],
      dueDate: map['due_date'],
      completed: map['completed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  ActionItem copyWith({
    String? id,
    String? mentorshipId,
    String? task,
    String? description,
    String? dueDate,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActionItem(
      id: id ?? this.id,
      mentorshipId: mentorshipId ?? this.mentorshipId,
      task: task ?? this.task,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ActionItem{id: $id, mentorshipId: $mentorshipId, task: $task, completed: $completed, dueDate: $dueDate}';
  }
}