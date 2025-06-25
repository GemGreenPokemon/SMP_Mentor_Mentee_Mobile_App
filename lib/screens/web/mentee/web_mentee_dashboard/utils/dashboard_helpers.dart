import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import 'dashboard_constants.dart';

class DashboardHelpers {
  // Color helpers
  static Color getColorFromString(String? colorString) {
    switch (colorString?.toLowerCase()) {
      case 'blue':
        return DashboardColors.accentBlue;
      case 'green':
        return DashboardColors.accentGreen;
      case 'orange':
        return DashboardColors.accentOrange;
      case 'red':
        return DashboardColors.accentRed;
      case 'purple':
        return DashboardColors.accentPurple;
      default:
        return DashboardColors.accentBlue;
    }
  }

  static Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return DashboardColors.errorRed;
      case 'medium':
        return DashboardColors.warningYellow;
      case 'low':
        return DashboardColors.successGreen;
      default:
        return DashboardColors.infoBlue;
    }
  }

  // Icon helpers
  static IconData getIconFromString(String? iconString) {
    switch (iconString?.toLowerCase()) {
      case 'check_circle':
        return Icons.check_circle;
      case 'event_available':
        return Icons.event_available;
      case 'person_add':
        return Icons.person_add;
      case 'folder_open':
        return Icons.folder_open;
      case 'assignment':
        return Icons.assignment;
      case 'message':
        return Icons.message;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.info;
    }
  }

  static IconData getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'task_completed':
        return Icons.check_circle;
      case 'meeting_attended':
        return Icons.event_available;
      case 'resource_accessed':
        return Icons.folder_open;
      case 'message_sent':
        return Icons.send;
      case 'checklist_updated':
        return Icons.checklist;
      default:
        return Icons.update;
    }
  }

  // Date & Time helpers
  static String formatRelativeTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'Unknown';
    
    // This is a simplified version - in production, you'd parse the actual date
    // and calculate the relative time properly
    if (timeString.contains('ago')) return timeString;
    if (timeString.contains('Today')) return timeString;
    if (timeString.contains('Tomorrow')) return timeString;
    if (timeString.contains('Yesterday')) return timeString;
    
    return timeString;
  }

  static String formatMeetingTime(String? time) {
    if (time == null || time.isEmpty) return 'Time not set';
    return time;
  }

  // Progress helpers
  static String getProgressPercentage(double value) {
    return '${(value * 100).toInt()}%';
  }

  static Color getProgressColor(double value) {
    if (value >= 0.8) return DashboardColors.successGreen;
    if (value >= 0.6) return DashboardColors.warningYellow;
    return DashboardColors.errorRed;
  }

  // Navigation helpers
  static int getTabIndexFromRoute(String? route) {
    switch (route) {
      case '/dashboard':
        return 0;
      case '/schedule':
        return 1;
      case '/resources':
        return 2;
      case '/checklist':
        return 3;
      case '/meeting-notes':
        return 4;
      case '/newsletters':
        return 5;
      case '/announcements':
        return 6;
      case '/settings':
        return 7;
      default:
        return 0;
    }
  }

  // Validation helpers
  static bool hasValidMentor(MentorInfo? mentor) {
    return mentor != null && mentor.id.isNotEmpty;
  }

  static bool hasAnnouncements(List<Announcement> announcements) {
    return announcements.isNotEmpty;
  }

  static bool hasMeetings(List<Meeting> meetings) {
    return meetings.isNotEmpty;
  }

  // Display helpers
  static String getPriorityText(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MEDIUM';
      case 'low':
        return 'LOW';
      default:
        return '';
    }
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Quick access items
  static List<Map<String, dynamic>> getQuickAccessItems() {
    return [
      {
        'title': 'My Checklist',
        'icon': Icons.checklist,
        'route': '/checklist',
      },
      {
        'title': 'Resources',
        'icon': Icons.folder_open,
        'route': '/resources',
      },
      {
        'title': 'Meeting Notes',
        'icon': Icons.note,
        'route': '/meeting-notes',
      },
      {
        'title': 'Newsletters',
        'icon': Icons.newspaper,
        'route': '/newsletters',
      },
      {
        'title': 'Schedule Meeting',
        'icon': Icons.calendar_today,
        'route': '/schedule',
      },
    ];
  }
}