import 'package:flutter/material.dart';

class ActivityItem {
  final String name;
  final String activity;
  final String time;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  const ActivityItem({
    required this.name,
    required this.activity,
    required this.time,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}