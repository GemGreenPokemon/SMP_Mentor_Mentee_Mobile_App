import 'package:flutter/material.dart';

class AcknowledgmentColors {
  static const Color primaryDark = Color(0xFF0F2D52);
  static const Color primaryLight = Color(0xFF1A4A7F);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color backgroundGrey = Color(0xFFF5F7FA);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textDark = Color(0xFF333333);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static final Color shadowLight = Colors.black.withOpacity(0.05);
  static final Color shadowMedium = Colors.black.withOpacity(0.1);
  static final Color shadowDark = Colors.black.withOpacity(0.2);
}

class AcknowledgmentSizes {
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;
  
  static const double buttonHeight = 50.0;
  static const double logoHeight = 120.0;
  static const double panelMargin = 24.0;
  static const double panelPadding = 32.0;
}

class AcknowledgmentTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeXXLarge,
    fontWeight: FontWeight.bold,
    color: AcknowledgmentColors.primaryDark,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeXLarge,
    fontWeight: FontWeight.bold,
    color: AcknowledgmentColors.primaryDark,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeLarge,
    fontWeight: FontWeight.bold,
    color: AcknowledgmentColors.primaryDark,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeMedium,
    color: AcknowledgmentColors.textDark,
    height: 1.5,
  );
  
  static const TextStyle bodySecondary = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeMedium,
    color: AcknowledgmentColors.textGrey,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: AcknowledgmentSizes.fontSizeMedium,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle panelTitle = TextStyle(
    color: Colors.white,
    fontSize: AcknowledgmentSizes.fontSizeXXLarge,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle panelSubtitle = TextStyle(
    color: Colors.white70,
    fontSize: AcknowledgmentSizes.fontSizeLarge,
  );
  
  static const TextStyle panelListItem = TextStyle(
    color: Colors.white,
    fontSize: AcknowledgmentSizes.fontSizeMedium,
  );
}

class AcknowledgmentStrings {
  static const String appTitle = 'Mentee Acknowledgment';
  static const String formTitle = 'Mentee Acknowledgment Form';
  static const String formSubtitle = 'Please review and complete the acknowledgment';
  static const String readAndAcknowledge = 'Please read and acknowledge the following:';
  static const String checkboxLabel = 'I have read and agree to the statements above';
  static const String nameFieldLabel = 'Please type your full name to complete the Mentee Acknowledgment Form:';
  static const String nameFieldHint = 'Type your full legal name here';
  static const String dateLabel = 'Date: ';
  static const String submitButton = 'SUBMIT & REGISTER';
  static const String errorAcknowledgment = 'Please check the acknowledgment box';
  static const String errorNameEmpty = 'Please enter your full name';
  static const String errorNameIncomplete = 'Please enter your full name (first and last name)';
  
  static const String panelDescription = 'Complete your acknowledgment form to finalize your registration as a mentee in the Student Mentorship Program.';
}