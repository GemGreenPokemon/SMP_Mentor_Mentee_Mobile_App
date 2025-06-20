import 'package:flutter/material.dart';

class NotificationItem {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;
  final bool isUnread;

  const NotificationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
    required this.isUnread,
  });
}