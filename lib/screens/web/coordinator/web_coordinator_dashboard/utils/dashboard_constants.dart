import 'package:flutter/material.dart';

class CoordinatorDashboardColors {
  // Primary colors
  static const Color primaryDark = Color(0xFF0F2D52);
  static const Color primaryDarkSecondary = Color(0xFF0A2340);
  static const Color primaryLight = Color(0xFF1A4A7F);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentPurple = Color(0xFF9C27B0);
  
  // Background colors
  static const Color backgroundMain = Color(0xFFF8FAFB);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundWhite = Colors.white;
  
  // Text colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color textDarkGrey = Color(0xFF6B7280);
  
  // Status colors
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Colors.grey;
  static const Color statusPending = Colors.orange;
  static const Color statusAvailable = Colors.green;
  static const Color statusAssigned = Colors.blue;
  static const Color statusRequested = Colors.orange;
  
  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);
}

class CoordinatorDashboardDimensions {
  // Sidebar
  static const double sidebarWidth = 250.0;
  static const double sidebarItemHeight = 48.0;
  
  // Padding and margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Card dimensions
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 8.0;
  
  // Icon sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 60.0;
  
  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
}

class CoordinatorDashboardStrings {
  // App title
  static const String appTitle = 'SMP Coordinator';
  
  // Default coordinator name
  static const String defaultCoordinatorName = 'Clarissa Correa';
  static const String coordinatorRole = 'Program Coordinator';
  
  // Navigation items
  static const List<String> sidebarItems = [
    'Dashboard',
    'Mentors',
    'Mentees',
    'Matching',
    'User Management',
    'Reports',
    'Resources',
    'Announcements',
    'Newsletter',
    'Program Data',
    'Settings',
  ];
  
  // Dashboard sections
  static const String programOverview = 'Program Overview';
  static const String quickActions = 'Quick Actions';
  static const String directMessages = 'Direct Messages';
  static const String mentorMenteeAssignments = 'Mentor-Mentee Assignments';
  static const String recentActivity = 'Recent Activity';
  static const String upcomingEvents = 'Upcoming Events';
  static const String actionItems = 'Action Items';
  
  // Stats labels
  static const String activeMentors = 'Active Mentors';
  static const String activeMentees = 'Active Mentees';
  static const String successRate = 'Success Rate';
  static const String programCompletion = 'Program Completion';
  
  // Quick action labels
  static const String manageEvents = 'Manage Events';
  static const String qualtrics = 'Qualtrics';
  static const String resources = 'Resources';
  static const String announcements = 'Announcements';
  
  // Matching page
  static const String matchingTitle = 'Mentor-Mentee Matching';
  static const String matchingDescription = 'Pair mentors with compatible mentees based on their profiles, interests, and academic goals.';
  static const String autoMatch = 'Auto-Match';
  static const String matchingCriteria = 'Matching Criteria';
  static const String availableMentees = 'Available Mentees';
  static const String availableMentors = 'Available Mentors';
  static const String currentMatches = 'Current Matches';
}

class CoordinatorDashboardIcons {
  static const List<IconData> sidebarIcons = [
    Icons.dashboard,
    Icons.supervisor_account,
    Icons.people,
    Icons.handshake,
    Icons.manage_accounts,
    Icons.assessment,
    Icons.folder_open,
    Icons.campaign,
    Icons.newspaper,
    Icons.bar_chart,
    Icons.settings,
  ];
}