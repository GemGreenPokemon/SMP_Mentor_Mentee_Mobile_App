import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionUrl,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.meeting:
        return Icons.event;
      case NotificationType.task:
        return Icons.assignment;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.resource:
        return Icons.folder;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.meeting:
        return Colors.green;
      case NotificationType.task:
        return Colors.orange;
      case NotificationType.announcement:
        return Colors.red;
      case NotificationType.resource:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

enum NotificationType {
  message,
  meeting,
  task,
  announcement,
  resource,
  general,
}