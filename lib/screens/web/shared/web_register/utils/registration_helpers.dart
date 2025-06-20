import 'package:flutter/material.dart';
import '../models/role_selection.dart';

class RegistrationHelpers {
  static bool isDesktopOrTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768;
  }

  static EdgeInsets getFormPadding(bool isDesktop, bool isTablet) {
    return EdgeInsets.symmetric(
      horizontal: isDesktop || isTablet ? 48 : 24,
      vertical: 32,
    );
  }

  static double getMaxFormWidth(bool isDesktop, bool isTablet) {
    if (isDesktop) return 600;
    if (isTablet) return 500;
    return double.infinity;
  }

  static void showSnackBar(
    BuildContext context, 
    String message, 
    {Color backgroundColor = Colors.red, 
    Duration duration = const Duration(seconds: 5)}
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }


  static void navigateToLogin(BuildContext context) {
    Navigator.pop(context);
  }

  static List<Color> getBackgroundGradientColors() {
    return [
      const Color(0xFF0F2D52).withOpacity(0.1),
      Colors.white,
      Colors.white,
      const Color(0xFF0F2D52).withOpacity(0.1),
    ];
  }

  static BoxDecoration getPanelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF0F2D52),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration getFormContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}