import 'package:flutter/material.dart';

class RegistrationConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Color(0xFF6B7280);
  static const Color redColor = Colors.red;
  static const Color greenColor = Colors.green;
  static const Color orangeColor = Colors.orange;
  static const Color blueColor = Colors.blue;
  
  // Padding & Margins
  static const double defaultPadding = 24.0;
  static const double largePadding = 48.0;
  static const double smallPadding = 16.0;
  static const double verticalSpacing = 32.0;
  static const double fieldSpacing = 20.0;
  
  // Text Sizes
  static const double titleFontSize = 32.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double labelFontSize = 18.0;
  static const double buttonFontSize = 16.0;
  
  // Widget Sizes
  static const double buttonHeight = 50.0;
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double logoHeight = 120.0;
  
  // Constraints
  static const double maxFormWidth = 600.0;
  static const double maxFormWidthTablet = 500.0;
  static const double developerFormWidth = 500.0;
  static const double developerFormWidthTablet = 450.0;
  
  // Animations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOut;
  
  // Validation
  static const int passwordMinLength = 6;
  static const int studentIdLength = 8;
  
  // Messages
  static const String roleSelectionError = 'Please select a role';
  static const String registrationSuccessMessage = 'Registration successful! Please check your email to verify your account.';
  static const String nameNotApprovedMessage = 'Your name is not on the approved list. Please contact your coordinator.';
  static const String emailAlreadyInUseMessage = 'An account with this email already exists.';
  static const String weakPasswordMessage = 'Password is too weak. Please choose a stronger password.';
  static const String invalidEmailMessage = 'Please enter a valid email address.';
  static const String coordinatorApprovalNote = 'Note: Coordinator accounts require approval';
  static const String developerWarningMessage = 'This option is for development only and should be removed in production.';
  static const String developerInfoMessage = 'This account bypasses database validation for quick testing.';
}