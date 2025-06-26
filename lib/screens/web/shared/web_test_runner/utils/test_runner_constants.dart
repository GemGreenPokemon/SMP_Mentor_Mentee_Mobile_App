import 'package:flutter/material.dart';

class TestRunnerColors {
  static const Color primary = Color(0xFF0F2D52);
  static const Color secondary = Color(0xFF1976D2);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color pending = Colors.grey;
}

class TestRunnerDurations {
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration testTimeout = Duration(seconds: 60);
  static const Duration refreshInterval = Duration(minutes: 5);
}

class TestRunnerSizes {
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  static const double borderRadius = 8.0;
  static const double maxDialogWidth = 800.0;
}