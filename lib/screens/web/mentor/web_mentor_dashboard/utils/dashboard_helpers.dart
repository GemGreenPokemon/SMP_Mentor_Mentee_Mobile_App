import 'package:flutter/material.dart';
import '../utils/dashboard_constants.dart';

class DashboardHelpers {
  // Calculate goal progress
  static double calculateGoalProgress(List<dynamic>? goals) {
    if (goals == null || goals.isEmpty) return 0.0;
    
    final completedGoals = goals.where((g) => g['completed'] == true).length;
    return completedGoals / goals.length;
  }

  // Get priority color
  static Color getPriorityColor(String? priority) {
    if (priority == null || priority == 'none') return DashboardColors.accentBlueLight;
    
    switch (priority) {
      case 'high':
        return DashboardColors.statusRed;
      case 'medium':
        return DashboardColors.statusOrange;
      case 'low':
        return DashboardColors.statusGreen;
      default:
        return DashboardColors.accentBlueLight;
    }
  }

  // Get priority text
  static String getPriorityText(String? priority) {
    if (priority == null || priority == 'none') return '';
    
    switch (priority) {
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MEDIUM';
      case 'low':
        return 'LOW';
      default:
        return '';
    }
  }

  // Get activity icon from string
  static IconData getActivityIcon(String iconName) {
    switch (iconName) {
      case 'event_available':
        return Icons.event_available;
      case 'check_circle':
        return Icons.check_circle;
      case 'folder_open':
        return Icons.folder_open;
      case 'login':
        return Icons.login;
      default:
        return Icons.info_outline;
    }
  }

  // Get activity color from string
  static Color getActivityColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.amber;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toInt()}%';
  }

  // Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DashboardColors.statusGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
        ),
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DashboardColors.statusRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
        ),
      ),
    );
  }

  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DashboardColors.statusOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardSizes.cardBorderRadius),
        ),
      ),
    );
  }
}