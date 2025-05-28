class Checklist {
  final String id;
  final String userId;
  final String title;
  final bool isCompleted;
  final String? dueDate;
  final String? assignedBy;
  final String? category;
  final DateTime? createdAt;

  Checklist({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.assignedBy,
    this.category,
    this.createdAt,
  });

  factory Checklist.fromMap(Map<String, dynamic> map) {
    return Checklist(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      dueDate: map['dueDate'],
      assignedBy: map['assignedBy'],
      category: map['category'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'dueDate': dueDate,
      'assignedBy': assignedBy,
      'category': category,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  Checklist copyWith({
    String? id,
    String? userId,
    String? title,
    bool? isCompleted,
    String? dueDate,
    String? assignedBy,
    String? category,
    DateTime? createdAt,
  }) {
    return Checklist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      assignedBy: assignedBy ?? this.assignedBy,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}