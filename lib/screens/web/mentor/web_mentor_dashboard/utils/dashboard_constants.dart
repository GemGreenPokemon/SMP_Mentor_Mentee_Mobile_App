import 'package:flutter/material.dart';

class DashboardColors {
  // Primary colors
  static const Color primaryDark = Color(0xFF0F2D52);
  static const Color primaryDarkSecondary = Color(0xFF0A2340);
  static const Color primaryLight = Color(0xFF1A4A7F);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentBlueSecondary = Color(0xFF357ABD);
  static const Color accentBlueLight = Color(0xFF2196F3);
  
  // Background colors
  static const Color backgroundMain = Color(0xFFF8FAFB);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundWhite = Colors.white;
  
  // Text colors
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color textDarkGrey = Color(0xFF6B7280);
  
  // Status colors
  static const Color statusGreen = Colors.green;
  static const Color statusRed = Colors.red;
  static const Color statusOrange = Colors.orange;
  static const Color statusPurple = Colors.purple;
  static const Color statusAmber = Colors.amber;
  
  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderGrey = Color(0xFFE0E0E0);
}

class DashboardSizes {
  // Sidebar
  static const double sidebarWidth = 280.0;
  static const double sidebarAnimationOffset = -280.0;
  
  // Cards
  static const double cardElevation = 2.0;
  static const double cardPadding = 20.0;
  static const double cardBorderRadius = 8.0;
  
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  
  // Font sizes
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 18.0;
  static const double fontXXLarge = 24.0;
  static const double fontTitle = 28.0;
}

class DashboardDurations {
  static const Duration sidebarAnimation = Duration(milliseconds: 300);
  static const Duration hoverAnimation = Duration(milliseconds: 200);
  static const Duration fadeAnimation = Duration(milliseconds: 300);
}

class DashboardStrings {
  // Titles
  static const String appTitle = 'SMP Mentor Portal';
  static const String appSubtitle = 'Excellence in Mentorship';
  static const String needHelp = 'Need Help?';
  
  // Status
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  
  // Actions
  static const String viewAll = 'View All';
  static const String viewCalendar = 'View Calendar';
  static const String close = 'Close';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String remove = 'Remove';
  static const String select = 'Select';
  static const String sendMessage = 'Send Message';
  static const String scheduleeMeeting = 'Schedule Meeting';
  static const String addMentee = 'Add Mentee';
  static const String removeMentee = 'Remove Mentee';
  static const String editProfile = 'Edit Profile';
  static const String logout = 'Logout';
  static const String markAllAsRead = 'Mark all as read';
  static const String checkIn = 'Check In';
  
  // Sections
  static const String yourMentees = 'Your Mentees';
  static const String upcomingMeetings = 'Upcoming Meetings';
  static const String announcements = 'Announcements';
  static const String recentActivity = 'Recent Activity';
  static const String notifications = 'Notifications';
  static const String overallProgress = 'Overall Progress';
  static const String goalsCompleted = 'Goals Completed';
  static const String availableMentees = 'Available Mentees';
  
  // Messages
  static const String errorLoadingData = 'Error loading dashboard data';
  static const String noDataAvailable = 'No data available';
  static const String noGoalsSet = 'No goals set yet';
  static const String noUpcomingMeetings = 'No upcoming meetings scheduled';
  static const String noActionItems = 'No action items';
  static const String notMetYet = 'Not met yet';
  static const String lastMeeting = 'Last meeting: ';
  static const String progress = 'Progress:';
  static const String goals = 'Goals';
  static const String actionItems = 'Action Items';
  static const String due = 'Due: ';
  static const String next = 'Next';
  
  // Search
  static const String searchMentees = 'Search mentees...';
  static const String allMentees = 'All Mentees';
  
  // Tooltips
  static const String search = 'Search';
  static const String coordinator = 'Coordinator';
  static const String message = 'Message';
  static const String details = 'Details';
}