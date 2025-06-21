class Newsletter {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final List<String> highlights;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Newsletter({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.highlights,
    this.authorId,
    this.authorName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Newsletter.fromJson(Map<String, dynamic> json) {
    return Newsletter(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      highlights: List<String>.from(json['highlights'] ?? []),
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'highlights': highlights,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Newsletter copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    List<String>? highlights,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Newsletter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      highlights: highlights ?? this.highlights,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}