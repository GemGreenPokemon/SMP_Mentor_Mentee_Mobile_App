enum ReportType {
  overview('Overview', 'General overview of all metrics'),
  attendance('Attendance', 'Meeting attendance records'),
  goalProgress('Goal Progress', 'Progress on mentee goals'),
  meetingNotes('Meeting Notes', 'Notes from mentoring sessions'),
  academicPerformance('Academic Performance', 'Academic metrics and progress');

  final String displayName;
  final String description;
  
  const ReportType(this.displayName, this.description);
}