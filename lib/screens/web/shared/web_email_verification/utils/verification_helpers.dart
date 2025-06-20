import 'package:flutter/material.dart';
import 'verification_constants.dart';

class VerificationHelpers {
  /// Gets the appropriate route based on user role
  static String getRouteForRole(String? role) {
    if (role == null) return VerificationConstants.defaultRoute;
    
    final lowercaseRole = role.toLowerCase();
    return VerificationConstants.roleRoutes[lowercaseRole] ?? 
           VerificationConstants.defaultRoute;
  }
  
  /// Shows a snackbar with the given message and color
  static void showSnackBar(
    BuildContext context, 
    String message, 
    {Color? backgroundColor}
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: VerificationConstants.snackBarDuration,
      ),
    );
  }
  
  /// Shows a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: VerificationConstants.successColor
    );
  }
  
  /// Shows an error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: VerificationConstants.errorColor
    );
  }
  
  /// Navigates to the appropriate dashboard after verification
  static void navigateToDashboard(BuildContext context, String? userRole) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = getRouteForRole(userRole);
      Navigator.pushReplacementNamed(context, route);
    });
  }
  
  /// Formats error messages
  static String formatErrorMessage(dynamic error) {
    return '${VerificationConstants.errorSendingEmailPrefix}${error.toString()}';
  }
}