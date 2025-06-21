import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/summary_card_data.dart';
import '../models/activity_item.dart';
import '../models/attendance_record.dart';
import '../models/goal_progress.dart';
import '../models/meeting_note.dart';
import '../models/academic_performance.dart';

class ReportHelpers {
  static final DateFormat dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat timeFormat = DateFormat('h:mm a');
  
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  static String formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(timestamp);
    }
  }
  
  static Color getAttendanceStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.excused:
        return Colors.orange;
      case AttendanceStatus.late:
        return Colors.yellow[700]!;
    }
  }
  
  // Mock data generators
  static List<String> getMockMentees() {
    return [
      'All Mentees',
      'Alice Johnson',
      'Bob Wilson',
      'Carlos Rodriguez',
    ];
  }
  
  static List<SummaryCardData> generateSummaryCards(String selectedMentee) {
    return [
      SummaryCardData(
        title: 'Total Meetings',
        value: '24',
        icon: Icons.event,
        color: Colors.blue,
        subtitle: '+12% from last period',
      ),
      SummaryCardData(
        title: 'Attendance Rate',
        value: '92%',
        icon: Icons.check_circle,
        color: Colors.green,
        subtitle: 'Above target',
      ),
      SummaryCardData(
        title: 'Goals Completed',
        value: '18/25',
        icon: Icons.flag,
        color: Colors.orange,
        subtitle: '72% completion rate',
      ),
      SummaryCardData(
        title: 'Active Mentees',
        value: selectedMentee == 'All Mentees' ? '3' : '1',
        icon: Icons.people,
        color: Colors.purple,
        subtitle: 'All engaged',
      ),
    ];
  }
  
  static List<ActivityItem> generateRecentActivities() {
    final now = DateTime.now();
    return [
      ActivityItem(
        name: 'Alice Johnson',
        activity: 'Completed "Resume Building" goal',
        time: '2 hours ago',
        icon: Icons.check_circle,
        color: Colors.green,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityItem(
        name: 'Bob Wilson',
        activity: 'Submitted progress update',
        time: '5 hours ago',
        icon: Icons.description,
        color: Colors.blue,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityItem(
        name: 'Carlos Rodriguez',
        activity: 'Scheduled meeting for next week',
        time: '1 day ago',
        icon: Icons.event,
        color: Colors.orange,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityItem(
        name: 'Alice Johnson',
        activity: 'Updated career objectives',
        time: '2 days ago',
        icon: Icons.edit,
        color: Colors.purple,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      ActivityItem(
        name: 'System',
        activity: 'Monthly reports generated',
        time: '3 days ago',
        icon: Icons.assessment,
        color: Colors.grey,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
  
  static List<AttendanceRecord> generateAttendanceRecords() {
    final now = DateTime.now();
    return [
      AttendanceRecord(
        date: 'May 15, 2024',
        mentee: 'Alice Johnson',
        meetingType: 'Weekly Check-in',
        status: AttendanceStatus.present,
        duration: '45 min',
        timestamp: DateTime(2024, 5, 15),
      ),
      AttendanceRecord(
        date: 'May 14, 2024',
        mentee: 'Bob Wilson',
        meetingType: 'Career Planning',
        status: AttendanceStatus.present,
        duration: '60 min',
        timestamp: DateTime(2024, 5, 14),
      ),
      AttendanceRecord(
        date: 'May 13, 2024',
        mentee: 'Carlos Rodriguez',
        meetingType: 'Weekly Check-in',
        status: AttendanceStatus.absent,
        duration: '-',
        timestamp: DateTime(2024, 5, 13),
      ),
      AttendanceRecord(
        date: 'May 10, 2024',
        mentee: 'Alice Johnson',
        meetingType: 'Goal Review',
        status: AttendanceStatus.present,
        duration: '30 min',
        timestamp: DateTime(2024, 5, 10),
      ),
    ];
  }
  
  static List<GoalProgress> generateGoalProgress() {
    return [
      GoalProgress(
        menteeName: 'Alice Johnson',
        goals: [
          Goal(
            title: 'Complete Resume',
            progress: 100,
            color: Colors.green,
            targetDate: DateTime(2024, 5, 1),
            status: GoalStatus.completed,
          ),
          Goal(
            title: 'Apply to 5 Internships',
            progress: 60,
            color: Colors.orange,
            targetDate: DateTime(2024, 6, 1),
            status: GoalStatus.inProgress,
          ),
          Goal(
            title: 'Improve GPA to 3.5',
            progress: 75,
            color: Colors.blue,
            targetDate: DateTime(2024, 12, 31),
            status: GoalStatus.inProgress,
          ),
        ],
      ),
      GoalProgress(
        menteeName: 'Bob Wilson',
        goals: [
          Goal(
            title: 'Complete Resume',
            progress: 100,
            color: Colors.green,
            targetDate: DateTime(2024, 5, 1),
            status: GoalStatus.completed,
          ),
          Goal(
            title: 'Apply to 5 Internships',
            progress: 60,
            color: Colors.orange,
            targetDate: DateTime(2024, 6, 1),
            status: GoalStatus.inProgress,
          ),
          Goal(
            title: 'Improve GPA to 3.5',
            progress: 75,
            color: Colors.blue,
            targetDate: DateTime(2024, 12, 31),
            status: GoalStatus.inProgress,
          ),
        ],
      ),
      GoalProgress(
        menteeName: 'Carlos Rodriguez',
        goals: [
          Goal(
            title: 'Complete Resume',
            progress: 100,
            color: Colors.green,
            targetDate: DateTime(2024, 5, 1),
            status: GoalStatus.completed,
          ),
          Goal(
            title: 'Apply to 5 Internships',
            progress: 60,
            color: Colors.orange,
            targetDate: DateTime(2024, 6, 1),
            status: GoalStatus.inProgress,
          ),
          Goal(
            title: 'Improve GPA to 3.5',
            progress: 75,
            color: Colors.blue,
            targetDate: DateTime(2024, 12, 31),
            status: GoalStatus.inProgress,
          ),
        ],
      ),
    ];
  }
  
  static List<MeetingNote> generateMeetingNotes() {
    return [
      MeetingNote(
        id: '1',
        menteeName: 'Alice Johnson',
        date: DateTime(2024, 5, 15),
        meetingType: 'Weekly Check-in',
        notes: 'Discussed progress on resume building. Alice has completed her first draft and will send it for review. Planning to apply to 3 internships this week.',
        actionItems: [
          'Review resume draft',
          'Apply to 3 internships',
          'Schedule mock interview',
        ],
      ),
      MeetingNote(
        id: '2',
        menteeName: 'Bob Wilson',
        date: DateTime(2024, 5, 14),
        meetingType: 'Career Planning Session',
        notes: 'Explored career options in psychology. Bob is interested in clinical psychology and will research graduate programs. Set up informational interview with alumni.',
        actionItems: [
          'Research graduate programs',
          'Contact alumni for interview',
          'Update career goals document',
        ],
      ),
      MeetingNote(
        id: '3',
        menteeName: 'Carlos Rodriguez',
        date: DateTime(2024, 5, 10),
        meetingType: 'Academic Support',
        notes: 'Reviewed study strategies for upcoming finals. Carlos will implement the Pomodoro technique and create a study schedule. Follow up next week.',
        actionItems: [
          'Create study schedule',
          'Implement Pomodoro technique',
          'Join study group for Chemistry',
        ],
      ),
    ];
  }
  
  static List<AcademicPerformance> generateAcademicPerformance() {
    return [
      AcademicPerformance(
        menteeName: 'Alice Johnson',
        currentGPA: 3.4,
        targetGPA: 3.5,
        creditsCompleted: 45,
        totalCredits: 120,
        status: AcademicStatus.onTrack,
      ),
      AcademicPerformance(
        menteeName: 'Bob Wilson',
        currentGPA: 3.7,
        targetGPA: 3.8,
        creditsCompleted: 60,
        totalCredits: 120,
        status: AcademicStatus.excellent,
      ),
      AcademicPerformance(
        menteeName: 'Carlos Rodriguez',
        currentGPA: 2.8,
        targetGPA: 3.0,
        creditsCompleted: 30,
        totalCredits: 120,
        status: AcademicStatus.needsSupport,
      ),
    ];
  }
}