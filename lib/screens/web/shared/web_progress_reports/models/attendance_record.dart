class AttendanceRecord {
  final String date;
  final String mentee;
  final String meetingType;
  final AttendanceStatus status;
  final String duration;
  final DateTime timestamp;

  const AttendanceRecord({
    required this.date,
    required this.mentee,
    required this.meetingType,
    required this.status,
    required this.duration,
    required this.timestamp,
  });
}

enum AttendanceStatus {
  present('Present'),
  absent('Absent'),
  excused('Excused'),
  late('Late');

  final String displayName;
  const AttendanceStatus(this.displayName);
}