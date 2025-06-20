import 'checklist_item.dart';

class Checklist {
  final String id;
  final String title;
  final String description;
  final List<ChecklistItem> items;
  final bool isCustom;
  final DateTime createdAt;
  final String? createdBy;
  final String? assignedTo;

  Checklist({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
    this.isCustom = false,
    DateTime? createdAt,
    this.createdBy,
    this.assignedTo,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (items.isEmpty) return 0.0;
    final completedCount = items.where((item) => item.completed).length;
    return completedCount / items.length;
  }

  int get completedItemsCount => items.where((item) => item.completed).length;

  int get totalItemsCount => items.length;

  bool get isCompleted => progress == 1.0;

  Checklist copyWith({
    String? id,
    String? title,
    String? description,
    List<ChecklistItem>? items,
    bool? isCustom,
    DateTime? createdAt,
    String? createdBy,
    String? assignedTo,
  }) {
    return Checklist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'assignedTo': assignedTo,
    };
  }

  factory Checklist.fromMap(Map<String, dynamic> map) {
    return Checklist(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromMap(item))
              .toList() ??
          [],
      isCustom: map['isCustom'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'],
      assignedTo: map['assignedTo'],
    );
  }
}