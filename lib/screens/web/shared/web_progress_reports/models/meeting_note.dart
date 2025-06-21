class MeetingNote {
  final String id;
  final String menteeName;
  final DateTime date;
  final String meetingType;
  final String notes;
  final List<String> actionItems;
  final String followUp;

  const MeetingNote({
    required this.id,
    required this.menteeName,
    required this.date,
    required this.meetingType,
    required this.notes,
    this.actionItems = const [],
    this.followUp = '',
  });
}