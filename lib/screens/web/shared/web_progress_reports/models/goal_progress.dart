import 'package:flutter/material.dart';

class GoalProgress {
  final String menteeName;
  final List<Goal> goals;

  const GoalProgress({
    required this.menteeName,
    required this.goals,
  });
}

class Goal {
  final String title;
  final double progress; // 0-100
  final Color color;
  final String description;
  final DateTime targetDate;
  final GoalStatus status;

  const Goal({
    required this.title,
    required this.progress,
    required this.color,
    this.description = '',
    required this.targetDate,
    required this.status,
  });
}

enum GoalStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  completed('Completed'),
  overdue('Overdue');

  final String displayName;
  const GoalStatus(this.displayName);
}