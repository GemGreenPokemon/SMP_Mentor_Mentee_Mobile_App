import 'package:flutter/material.dart';

class ResourceConstants {
  // Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color cardBackground = Colors.white;
  static const Color sidebarBackground = Colors.white;
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // File Type Colors
  static const Color pdfColor = Colors.red;
  static const Color docxColor = Colors.blue;
  static const Color xlsxColor = Colors.green;
  static const Color linkColor = Colors.purple;
  static const Color defaultFileColor = Colors.grey;
  
  // Spacing
  static const double largePadding = 24.0;
  static const double mediumPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double tinyPadding = 4.0;
  
  // Sizing
  static const double sidebarWidth = 250.0;
  static const double searchBarWidth = 300.0;
  static const double dialogWidth = 500.0;
  static const double maxDialogWidth = 600.0;
  static const double iconSizeLarge = 48.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeSmall = 20.0;
  
  // Text Sizes
  static const double titleTextSize = 18.0;
  static const double subtitleTextSize = 16.0;
  static const double bodyTextSize = 14.0;
  static const double captionTextSize = 12.0;
  static const double smallTextSize = 11.0;
  
  // Layout
  static const double cardBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double cardAspectRatio = 1.5;
  static const double dataRowMinHeight = 48.0;
  static const double dataRowMaxHeight = 56.0;
  static const double chipHeight = 24.0;
  
  // Breakpoints
  static const double wideScreenBreakpoint = 1200.0;
  static const double mediumScreenBreakpoint = 800.0;
  static const double smallScreenBreakpoint = 600.0;
  
  // Grid Configuration
  static int getGridCrossAxisCount(double screenWidth) {
    if (screenWidth > wideScreenBreakpoint) return 4;
    if (screenWidth > mediumScreenBreakpoint) return 3;
    if (screenWidth > smallScreenBreakpoint) return 2;
    return 1;
  }
  
  // Messages
  static const String uploadSuccessMessage = 'Resource uploaded successfully';
  static const String updateSuccessMessage = 'Document updated successfully';
  static const String deleteSuccessMessage = 'Document deleted successfully';
  static const String bulkDeleteSuccessMessage = 'Documents deleted successfully';
  static const String assignmentSuccessMessage = 'Resource assigned to';
  static const String unassignSuccessMessage = 'Resource unassigned from all mentees';
  static const String downloadingMessage = 'Downloading';
  static const String analyticsComingSoonMessage = 'Analytics feature coming soon';
  static const String historyComingSoonMessage = 'Resource history feature coming soon';
  
  // Tooltips
  static const String uploadTooltip = 'Upload Resource';
  static const String manageTooltip = 'Manage Resources';
  static const String settingsTooltip = 'Settings';
  
  // Tab Labels
  static const String generalResourcesTab = 'General Resources';
  static const String documentsTab = 'Documents';
  
  // Section Titles
  static const String quickActionsTitle = 'Quick Actions';
  static const String filterByCategoryTitle = 'Filter by Category';
  static const String quickLinksTitle = 'Quick Links';
  static const String programResourcesTitle = 'Program Resources';
}