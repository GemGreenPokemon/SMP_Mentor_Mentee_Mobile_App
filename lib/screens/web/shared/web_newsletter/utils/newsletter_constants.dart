import 'package:flutter/material.dart';

class NewsletterConstants {
  // Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color headerBackground = Color(0xFFFAFAFA);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color highlightBackground = Color(0xFFF5F5F5);
  static const Color contactInfoBackground = Color(0xFFE3F2FD);
  
  // Spacing
  static const double largePadding = 48.0;
  static const double mediumPadding = 24.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 8.0;
  
  // Sizing
  static const double iconSizeLarge = 32.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeTiny = 16.0;
  
  // Text Sizes
  static const double titleTextSize = 28.0;
  static const double subtitleTextSize = 22.0;
  static const double bodyTextSize = 16.0;
  static const double captionTextSize = 14.0;
  static const double smallTextSize = 12.0;
  
  // Layout
  static const double maxDialogWidth = 800.0;
  static const double dialogHeightFactor = 0.9;
  static const double cardBorderRadius = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  static const double cardAspectRatio = 1.2;
  
  // Breakpoints
  static const double largeScreenBreakpoint = 1200.0;
  static const double mediumScreenBreakpoint = 800.0;
  
  // Grid Configuration
  static int getGridCrossAxisCount(double screenWidth) {
    if (screenWidth > largeScreenBreakpoint) return 3;
    if (screenWidth > mediumScreenBreakpoint) return 2;
    return 1;
  }
  
  // Contact Info
  static const String contactEmail = 'smp@university.edu';
  static const String contactPhone = '(123) 456-7890';
  static const String contactLocation = 'Student Center, Room 234';
  
  // Messages
  static const String noNewslettersMessage = 'No newsletters found';
  static const String downloadingMessage = 'Downloading PDF...';
  static const String shareMessagePrefix = 'Check out the';
  static const String shareMessageSuffix = 'from our Student Mentorship Program!';
  static const String additionalInfoTitle = 'Additional Information';
  static const String additionalInfoContent = 'For more details about any of these events or resources, please contact your mentor or the program coordinator. We look forward to seeing you at our upcoming events!';
  static const String createNewsletterTitle = 'Create New Newsletter';
  static const String createNewsletterMessage = 'Newsletter creation functionality will be implemented soon. This will allow you to compose and publish new newsletters for the mentorship program.';
}