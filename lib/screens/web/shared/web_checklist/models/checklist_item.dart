class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String? proof;
  final String? proofStatus; // 'pending', 'approved', 'rejected'
  final String? feedback;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.completed = false,
    this.proof,
    this.proofStatus,
    this.feedback,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    String? proof,
    String? proofStatus,
    String? feedback,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      proof: proof ?? this.proof,
      proofStatus: proofStatus ?? this.proofStatus,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'proof': proof,
      'proofStatus': proofStatus,
      'feedback': feedback,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completed: map['completed'] ?? false,
      proof: map['proof'],
      proofStatus: map['proofStatus'],
      feedback: map['feedback'],
    );
  }
}