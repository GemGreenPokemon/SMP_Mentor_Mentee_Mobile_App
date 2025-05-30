class MeetingNote {
  final String id;
  final String meetingId;
  final String authorId;
  final bool isShared;
  final bool isMentor;
  final String rawNote;
  final String? organizedNote;
  final bool isAiGenerated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MeetingNote({
    required this.id,
    required this.meetingId,
    required this.authorId,
    this.isShared = false,
    this.isMentor = false,
    required this.rawNote,
    this.organizedNote,
    this.isAiGenerated = false,
    this.createdAt,
    this.updatedAt,
  });

  factory MeetingNote.fromMap(Map<String, dynamic> map) {
    return MeetingNote(
      id: map['id'],
      meetingId: map['meeting_id'],
      authorId: map['author_id'],
      isShared: map['is_shared'] == 1,
      isMentor: map['is_mentor'] == 1,
      rawNote: map['raw_note'],
      organizedNote: map['organized_note'],
      isAiGenerated: map['is_ai_generated'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'author_id': authorId,
      'is_shared': isShared ? 1 : 0,
      'is_mentor': isMentor ? 1 : 0,
      'raw_note': rawNote,
      'organized_note': organizedNote,
      'is_ai_generated': isAiGenerated ? 1 : 0,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  MeetingNote copyWith({
    String? id,
    String? meetingId,
    String? authorId,
    bool? isShared,
    bool? isMentor,
    String? rawNote,
    String? organizedNote,
    bool? isAiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingNote(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      authorId: authorId ?? this.authorId,
      isShared: isShared ?? this.isShared,
      isMentor: isMentor ?? this.isMentor,
      rawNote: rawNote ?? this.rawNote,
      organizedNote: organizedNote ?? this.organizedNote,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}