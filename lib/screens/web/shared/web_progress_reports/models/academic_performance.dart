import 'package:flutter/material.dart';

class AcademicPerformance {
  final String menteeName;
  final double currentGPA;
  final double targetGPA;
  final int creditsCompleted;
  final int totalCredits;
  final AcademicStatus status;

  const AcademicPerformance({
    required this.menteeName,
    required this.currentGPA,
    required this.targetGPA,
    required this.creditsCompleted,
    required this.totalCredits,
    required this.status,
  });

  double get progressPercentage => (creditsCompleted / totalCredits) * 100;
}

enum AcademicStatus {
  excellent('Excellent', Colors.blue),
  onTrack('On Track', Colors.green),
  needsSupport('Needs Support', Colors.orange),
  atRisk('At Risk', Colors.red);

  final String displayName;
  final Color color;
  const AcademicStatus(this.displayName, this.color);
}