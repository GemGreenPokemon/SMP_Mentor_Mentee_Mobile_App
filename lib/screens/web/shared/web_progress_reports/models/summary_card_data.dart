import 'package:flutter/material.dart';

class SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool showTrend;
  final bool isPositiveTrend;

  const SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.showTrend = true,
    this.isPositiveTrend = true,
  });
}