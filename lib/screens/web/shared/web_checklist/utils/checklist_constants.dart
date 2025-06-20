import 'package:flutter/material.dart';

class ChecklistConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color customBadgeColor = Colors.purple;

  // Sizes
  static const double cardBorderRadius = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Grid Configuration
  static const int desktopGridColumns = 3;
  static const int tabletGridColumns = 2;
  static const int mobileGridColumns = 1;

  static const double desktopCardAspectRatio = 1.5;
  static const double tabletCardAspectRatio = 1.3;
  static const double mobileCardAspectRatio = 1.2;

  // Text Styles
  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  // Proof Status
  static const String proofStatusPending = 'pending';
  static const String proofStatusApproved = 'approved';
  static const String proofStatusRejected = 'rejected';

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Constraints
  static const double maxDialogWidth = 800.0;
  static const double maxContentWidth = 1400.0;
  static const double minDropdownWidth = 250.0;
  static const double menteeDropdownWidth = 300.0;
}