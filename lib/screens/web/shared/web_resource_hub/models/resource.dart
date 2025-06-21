class Resource {
  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final String category;
  final DateTime dateAdded;
  final String audience;
  final String url;
  final List<String> assignedTo;

  const Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.dateAdded,
    required this.audience,
    required this.url,
    required this.assignedTo,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ResourceType.fromString(json['type'] as String),
      category: json['category'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      audience: json['audience'] as String,
      url: json['url'] as String,
      assignedTo: List<String>.from(json['assignedTo'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'category': category,
      'dateAdded': dateAdded.toIso8601String(),
      'audience': audience,
      'url': url,
      'assignedTo': assignedTo,
    };
  }

  Resource copyWith({
    String? id,
    String? title,
    String? description,
    ResourceType? type,
    String? category,
    DateTime? dateAdded,
    String? audience,
    String? url,
    List<String>? assignedTo,
  }) {
    return Resource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      dateAdded: dateAdded ?? this.dateAdded,
      audience: audience ?? this.audience,
      url: url ?? this.url,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

enum ResourceType {
  pdf('PDF'),
  docx('DOCX'),
  xlsx('XLSX'),
  link('Link');

  final String value;
  const ResourceType(this.value);

  static ResourceType fromString(String type) {
    return ResourceType.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () => ResourceType.pdf,
    );
  }
}