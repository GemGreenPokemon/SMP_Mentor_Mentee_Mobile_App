import 'package:flutter/material.dart';

class VerificationConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color backgroundColor = Colors.white;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  
  // Timing
  static const Duration checkInterval = Duration(seconds: 3);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Sizes
  static const double iconSize = 40.0;
  static const double iconContainerSize = 80.0;
  static const double titleFontSize = 28.0;
  static const double bodyFontSize = 16.0;
  static const double smallFontSize = 14.0;
  static const double tinyFontSize = 12.0;
  static const double buttonHeight = 50.0;
  
  // Padding and Spacing
  static const double cardPadding = 32.0;
  static const double verticalSpacing = 24.0;
  static const double smallVerticalSpacing = 16.0;
  static const double horizontalPadding = 48.0;
  static const double mobileHorizontalPadding = 24.0;
  
  // Border Radius
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  static const double containerBorderRadius = 8.0;
  static const double iconContainerRadius = 40.0;
  
  // Max Widths
  static const double desktopMaxWidth = 600.0;
  static const double tabletMaxWidth = 500.0;
  
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