import 'package:flutter/material.dart';

class RegistrationConstants {
  // Colors (matching login design)
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color secondaryColor = Color(0xFF1E3A5F);
  static const Color tertiaryColor = Color(0xFF2D4A6E);
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Color(0xFF6B7280);
  static const Color redColor = Colors.red;
  static const Color greenColor = Colors.green;
  
  // Gradients (matching login design)
  static const List<Color> backgroundGradientColors = [
    primaryColor,
    secondaryColor,
    tertiaryColor,
  ];
  
  static const List<Color> brandingGradientColors = [
    primaryColor,
    Color(0xFF1A3A5C),
    tertiaryColor,
  ];
  
  static const List<Color> buttonGradientColors = [
    primaryColor,
    secondaryColor,
  ];
  
  // Padding & Margins (matching login design)
  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double extraLargePadding = 60.0;
  static const double smallPadding = 16.0;
  static const double verticalSpacing = 32.0;
  static const double fieldSpacing = 20.0;
  
  // Text Sizes
  static const double titleFontSize = 32.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double labelFontSize = 18.0;
  static const double buttonFontSize = 16.0;
  
  // Widget Sizes (matching login design)
  static const double buttonHeight = 56.0;
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  static const double logoHeight = 120.0;
  static const double mobileLogoHeight = 80.0;
  
  // Constraints (matching login design)
  static const double maxDesktopWidth = 1200.0;
  static const double maxDesktopHeight = 700.0;
  static const double maxFormWidth = 600.0;
  static const double maxFormWidthTablet = 500.0;
  
  // Animations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOut;
  
  // Validation
  static const int passwordMinLength = 6;
  static const int studentIdLength = 8;
  
  // Text Styles (matching login design)
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    letterSpacing: -0.5,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle brandingTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.2,
    height: 1.2,
  );
  
  // Icons (matching login design)
  static const IconData nameIcon = Icons.person_outline;
  static const IconData emailIcon = Icons.email_outlined;
  static const IconData passwordIcon = Icons.lock_outline;
  static const IconData studentIdIcon = Icons.badge_outlined;
  static const IconData visibilityIcon = Icons.visibility;
  static const IconData visibilityOffIcon = Icons.visibility_off;
  
  // Feature Icons
  static const IconData learningIcon = Icons.school_outlined;
  static const IconData calendarIcon = Icons.calendar_month_outlined;
  static const IconData progressIcon = Icons.trending_up_outlined;
  static const IconData communityIcon = Icons.people_outline;
  
  // Feature Items
  static const List<Map<String, dynamic>> features = [
    {'icon': learningIcon, 'text': 'Access Learning Resources'},
    {'icon': calendarIcon, 'text': 'Schedule Meetings'},
    {'icon': progressIcon, 'text': 'Track Progress'},
    {'icon': communityIcon, 'text': 'Connect with Community'},
  ];
  
  // Messages
  static const String registrationSuccessMessage = 'Registration successful! Please check your email to verify your account.';
  static const String nameNotApprovedMessage = 'Your name is not on the approved list. Please contact your coordinator.';
  static const String emailAlreadyInUseMessage = 'An account with this email already exists.';
  static const String weakPasswordMessage = 'Password is too weak. Please choose a stronger password.';
  static const String invalidEmailMessage = 'Please enter a valid email address.';
  
  // Legacy constants for old forms (kept to avoid build errors)
  static const Color orangeColor = Colors.orange;
  static const String roleSelectionError = 'Please select a role';
  static const String coordinatorApprovalNote = 'Note: Coordinator accounts require approval';
  static const String developerWarningMessage = 'This option is for development only and should be removed in production.';
  static const String developerInfoMessage = 'This account bypasses database validation for quick testing.';
  static const double developerFormWidth = 500.0;
  static const double developerFormWidthTablet = 450.0;
}