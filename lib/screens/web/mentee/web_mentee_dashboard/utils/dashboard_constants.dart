import 'package:flutter/material.dart';

// Colors
class DashboardColors {
  // Primary colors
  static const Color primaryDark = Color(0xFF0F2D52);
  static const Color primaryDarkSecondary = Color(0xFF0A2340);
  static const Color primaryLight = Color(0xFF1A4A7F);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentBlueSecondary = Color(0xFF357ABD);
  static const Color accentBlueLight = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF2B9348);
  static const Color accentOrange = Color(0xFFF39C12);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color accentPurple = Color(0xFF9B59B6);
  
  // Background colors
  static const Color backgroundMain = Color(0xFFF8FAFB);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundCard = Colors.white;
  static const Color backgroundSidebar = Color(0xFF0F2D52);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color textDarkGrey = Color(0xFF6B7280);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFFBDC3C7);
  
  // Status colors
  static const Color statusGreen = Colors.green;
  static const Color statusRed = Colors.red;
  static const Color statusOrange = Colors.orange;
  static const Color statusPurple = Colors.purple;
  static const Color statusAmber = Colors.amber;
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningYellow = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color infoBlue = Color(0xFF3498DB);
  
  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFCED6E0);
  
  // Shadow colors - for premium depth effects
  static final Color shadowLight = Colors.black.withOpacity(0.05);
  static final Color shadowMedium = Colors.black.withOpacity(0.08);
  static final Color shadowDark = Colors.black.withOpacity(0.15);
  static final Color shadowXDark = Colors.black.withOpacity(0.25);
  
  // Overlay colors - for glassmorphic effects
  static final Color overlayLight = Colors.white.withOpacity(0.05);
  static final Color overlayMedium = Colors.white.withOpacity(0.1);
  static final Color overlayDark = primaryDark.withOpacity(0.95);
}

// Sizes
class DashboardSizes {
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Component Sizes
  static const double sidebarWidth = 280.0;
  static const double topbarHeight = 80.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
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
  
  // Animation
  static const double sidebarAnimationOffset = -100.0;
  static const double cardHoverScale = 1.02;
  static const double buttonHoverScale = 1.05;
}

// Text Styles
class DashboardTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DashboardColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: DashboardColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DashboardColors.textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: DashboardColors.textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DashboardColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DashboardColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: DashboardColors.textMuted,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// Premium shadows for depth
class DashboardShadows {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: DashboardColors.shadowLight,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: DashboardColors.shadowDark,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> sidebarShadow = [
    BoxShadow(
      color: DashboardColors.shadowXDark,
      blurRadius: 32,
      offset: const Offset(4, 0),
    ),
  ];
  
  static List<BoxShadow> topbarShadow = [
    BoxShadow(
      color: DashboardColors.shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: DashboardColors.shadowMedium,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: DashboardColors.shadowLight,
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

// Durations
class DashboardDurations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration sidebarAnimation = Duration(milliseconds: 600);
  static const Duration cardAnimation = Duration(milliseconds: 400);
  static const Duration refreshAnimation = Duration(milliseconds: 1000);
}

// Curves
class DashboardCurves {
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutExpo;
}

// Premium elevation values for depth
class DashboardElevations {
  static const double cardResting = 2.0;
  static const double cardHover = 8.0;
  static const double cardPressed = 1.0;
  static const double sidebar = 16.0;
  static const double modal = 24.0;
  static const double topbar = 4.0;
}

// Blur values for glassmorphic effects
class DashboardBlur {
  static const double light = 8.0;
  static const double medium = 16.0;
  static const double heavy = 24.0;
  static const double backdrop = 32.0;
}

// Dashboard Strings
class DashboardStrings {
  // Titles
  static const String appTitle = 'SMP Mentee Portal';
  static const String appSubtitle = 'Your Journey to Success';
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
  static const String scheduleMeeting = 'Schedule Meeting';
  static const String editProfile = 'Edit Profile';
  static const String logout = 'Logout';
  static const String markAllAsRead = 'Mark all as read';
  static const String checkIn = 'Check In';
  
  // Sections
  static const String yourMentor = 'Your Mentor';
  static const String yourProgress = 'Your Progress';
  static const String upcomingMeetings = 'Upcoming Meetings';
  static const String announcements = 'Announcements';
  static const String recentActivity = 'Recent Activity';
  static const String notifications = 'Notifications';
  static const String checklistCompletion = 'Checklist Completion';
  static const String meetingAttendance = 'Meeting Attendance';
  
  // Messages
  static const String errorLoadingData = 'Error loading dashboard data';
  static const String noDataAvailable = 'No data available';
  static const String noAnnouncementsAtThisTime = 'No announcements at this time';
  static const String noUpcomingMeetings = 'No upcoming meetings scheduled';
  static const String noRecentActivity = 'No recent activity';
}