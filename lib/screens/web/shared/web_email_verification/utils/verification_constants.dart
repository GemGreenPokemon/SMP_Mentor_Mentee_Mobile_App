import 'package:flutter/material.dart';

class VerificationConstants {
  // Colors (matching login/registration design)
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color secondaryColor = Color(0xFF1E3A5F);
  static const Color tertiaryColor = Color(0xFF2D4A6E);
  static const Color backgroundColor = Colors.white;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  
  // Gradients (matching login/registration design)
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
  
  // Timing
  static const Duration checkInterval = Duration(seconds: 3);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Sizes (matching login/registration design)
  static const double iconSize = 40.0;
  static const double iconContainerSize = 80.0;
  static const double titleFontSize = 32.0;
  static const double bodyFontSize = 16.0;
  static const double smallFontSize = 14.0;
  static const double tinyFontSize = 12.0;
  static const double buttonHeight = 56.0;
  static const double logoHeight = 120.0;
  static const double mobileLogoHeight = 80.0;
  
  // Padding and Spacing (matching login/registration design)
  static const double defaultPadding = 16.0;
  static const double largePadding = 32.0;
  static const double extraLargePadding = 60.0;
  static const double cardPadding = 32.0;
  static const double verticalSpacing = 24.0;
  static const double smallVerticalSpacing = 16.0;
  static const double horizontalPadding = 48.0;
  static const double mobileHorizontalPadding = 24.0;
  
  // Border Radius (matching login/registration design)
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  static const double cardBorderRadius = 24.0;
  static const double buttonBorderRadius = 12.0;
  static const double containerBorderRadius = 12.0;
  static const double iconContainerRadius = 40.0;
  
  // Max Widths (matching login/registration design)
  static const double maxDesktopWidth = 1200.0;
  static const double maxDesktopHeight = 700.0;
  static const double desktopMaxWidth = 600.0;
  static const double tabletMaxWidth = 500.0;
  
  // Text Styles (matching login/registration design)
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
  static const IconData checkIcon = Icons.check_circle_outline;
  static const IconData errorIcon = Icons.error_outline;
  
  // Text Content
  static const String title = 'Verify Your Email';
  static const String description = 'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.';
  static const String resendButtonText = 'Resend Verification Email';
  static const String signOutText = 'Sign out and try with different account';
  static const String helpText = 'Didn\'t receive the email? Check your spam folder or click "Resend" above.';
  
  // Success/Error Messages
  static const String emailVerifiedMessage = 'Email verified successfully!';
  static const String verificationEmailSentMessage = 'Verification email sent! Please check your inbox.';
  static const String errorSendingEmailPrefix = 'Error sending email: ';
  
  // Route Names
  static const Map<String, String> roleRoutes = {
    'mentee': '/mentee',
    'mentor': '/mentor',
    'coordinator': '/coordinator',
  };
  static const String defaultRoute = '/';
}