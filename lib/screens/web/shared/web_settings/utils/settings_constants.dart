import 'package:flutter/material.dart';

class SettingsConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color sectionBackgroundColor = Colors.white;
  static const Color sectionBorderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Padding and Spacing
  static const double sectionPadding = 24.0;
  static const double sectionSpacing = 16.0;
  static const double itemSpacing = 16.0;
  
  // Border Radius
  static const double sectionBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Font Sizes
  static const double titleFontSize = 18.0;
  static const double subtitleFontSize = 14.0;
  static const double bodyFontSize = 16.0;
  
  // Language Options
  static const List<String> languageOptions = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];
  
  // Download Location Options
  static const List<String> downloadLocationOptions = [
    'Default Downloads Folder',
    'Documents',
    'Desktop',
    'Custom Location',
  ];
  
  // Default Settings Values
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultEmailNotifications = true;
  static const bool defaultDarkMode = false;
  static const String defaultLanguage = 'English';
  static const String defaultDownloadLocation = 'Default Downloads Folder';
  
  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration dialogAnimationDuration = Duration(milliseconds: 200);
  
  // Icons
  static const IconData notificationIcon = Icons.notifications_outlined;
  static const IconData appearanceIcon = Icons.palette_outlined;
  static const IconData storageIcon = Icons.folder_outlined;
  static const IconData accountIcon = Icons.person_outline;
  static const IconData excelIcon = Icons.table_chart_outlined;
  static const IconData userManagementIcon = Icons.group_outlined;
  static const IconData databaseIcon = Icons.storage_outlined;
  static const IconData helpIcon = Icons.help_outline;
  static const IconData developerIcon = Icons.code;
  
  // Section Titles
  static const String notificationSectionTitle = 'Notification Settings';
  static const String appearanceSectionTitle = 'Appearance';
  static const String storageSectionTitle = 'File Storage';
  static const String accountSectionTitle = 'Account Settings';
  static const String excelSectionTitle = 'Excel Upload';
  static const String userManagementSectionTitle = 'User Management';
  static const String databaseSectionTitle = 'Database Administration';
  static const String helpSectionTitle = 'Help & Support';
  static const String developerSectionTitle = 'Developer Tools';
}