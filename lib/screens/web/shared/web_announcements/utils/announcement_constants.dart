import 'package:flutter/material.dart';

class AnnouncementConstants {
  static const List<String> filterOptions = [
    'All',
    'High Priority',
    'Medium Priority',
    'Low Priority',
    'General'
  ];

  static final List<Map<String, dynamic>> sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.arrow_downward},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.arrow_upward},
    {'value': 'priority', 'label': 'Priority', 'icon': Icons.priority_high},
  ];

  static final Map<String, Map<String, dynamic>> priorityConfig = {
    'high': {
      'label': 'High',
      'displayText': 'HIGH PRIORITY',
      'color': Colors.red,
      'colorValue': 600,
    },
    'medium': {
      'label': 'Medium',
      'displayText': 'MEDIUM PRIORITY',
      'color': Colors.orange,
      'colorValue': 600,
    },
    'low': {
      'label': 'Low', 
      'displayText': 'LOW PRIORITY',
      'color': Colors.green,
      'colorValue': 600,
    },
    'none': {
      'label': 'General',
      'displayText': 'GENERAL',
      'color': Colors.blue,
      'colorValue': 600,
    },
  };

  static const Map<String, int> priorityOrder = {
    'high': 0,
    'medium': 1,
    'low': 2,
    'none': 3,
  };
}