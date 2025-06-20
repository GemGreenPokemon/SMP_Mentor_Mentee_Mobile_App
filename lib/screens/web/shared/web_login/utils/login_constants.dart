import 'package:flutter/material.dart';

class LoginConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color secondaryColor = Color(0xFF1E3A5F);
  static const Color tertiaryColor = Color(0xFF2D4A6E);
  
  // Gradients
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

  // Sizes
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double extraLargePadding = 60.0;
  
  // Constraints
  static const double maxDesktopWidth = 1200.0;
  static const double maxDesktopHeight = 700.0;
  static const double logoHeight = 120.0;
  static const double mobileLogoHeight = 80.0;
  static const double buttonHeight = 56.0;
  
  // Text Styles
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
  
  // Icons
  static const IconData emailIcon = Icons.email_outlined;
  static const IconData passwordIcon = Icons.lock_outline;
  static const IconData visibilityIcon = Icons.visibility;
  static const IconData visibilityOffIcon = Icons.visibility_off;
  
  // Feature Icons
  static const IconData learningIcon = Icons.school_outlined;
  static const IconData calendarIcon = Icons.calendar_month_outlined;
  static const IconData progressIcon = Icons.trending_up_outlined;
  static const IconData communityIcon = Icons.people_outline;

  // Error Messages
  static const Map<String, String> errorMessages = {
    'user-not-found': 'No account found with this email address.',
    'wrong-password': 'Incorrect password.',
    'invalid-email': 'Please enter a valid email address.',
    'user-disabled': 'This account has been disabled.',
    'too-many-requests': 'Too many failed attempts. Please try again later.',
  };

  // Validation Messages
  static const String emailRequired = 'Please enter your email';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Please enter your password';
  static const String passwordTooShort = 'Password must be at least 6 characters';

  // Feature Items
  static const List<Map<String, dynamic>> features = [
    {'icon': learningIcon, 'text': 'Access Learning Resources'},
    {'icon': calendarIcon, 'text': 'Schedule Meetings'},
    {'icon': progressIcon, 'text': 'Track Progress'},
    {'icon': communityIcon, 'text': 'Connect with Community'},
  ];
}