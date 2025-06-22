import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagingHelpers {
  /// Format timestamp for display
  static String formatTimestamp(DateTime? timestamp, BuildContext context) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat.jm().format(timestamp); // 3:45 PM
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat.EEEE().format(timestamp); // Monday
    } else if (now.year == timestamp.year) {
      // This year - show month and day
      return DateFormat.MMMd().format(timestamp); // Mar 15
    } else {
      // Different year - show full date
      return DateFormat.yMMMd().format(timestamp); // Mar 15, 2023
    }
  }
  
  /// Format message timestamp for chat bubbles
  static String formatMessageTime(DateTime timestamp) {
    return DateFormat.jm().format(timestamp); // 3:45 PM
  }
  
  /// Format last seen time
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(lastSeen);
    }
  }
  
  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return '${parts[0].substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
    }
  }
  
  /// Get avatar color based on name
  static Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFD32F2F), // Red
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFF57C00), // Orange
      const Color(0xFF0288D1), // Light Blue
      const Color(0xFF689F38), // Light Green
      const Color(0xFFE64A19), // Deep Orange
    ];
    
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
  
  /// Truncate message for preview
  static String truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }
  
  /// Validate message
  static bool isValidMessage(String message) {
    return message.trim().isNotEmpty && message.trim().length <= 1000;
  }
  
  /// Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Scroll to bottom of list
  static void scrollToBottom(ScrollController controller, {bool animated = true}) {
    if (!controller.hasClients) return;
    
    if (animated) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      controller.jumpTo(0.0);
    }
  }
  
  /// Check if should show date separator
  static bool shouldShowDateSeparator(DateTime current, DateTime? previous) {
    if (previous == null) return true;
    
    return current.year != previous.year ||
           current.month != previous.month ||
           current.day != previous.day;
  }
  
  /// Format date separator
  static String formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.year == date.year) {
      return DateFormat.MMMEd().format(date); // Mon, Mar 15
    } else {
      return DateFormat.yMMMEd().format(date); // Mon, Mar 15, 2023
    }
  }
  
  /// Parse mentions in message
  static List<TextSpan> parseMessage(String message, TextStyle baseStyle) {
    // Simple implementation - can be extended for mentions, links, etc.
    return [TextSpan(text: message, style: baseStyle)];
  }
}