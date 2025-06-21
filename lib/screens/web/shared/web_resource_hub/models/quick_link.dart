import 'package:flutter/material.dart';

class QuickLink {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? url;
  final VoidCallback? onTap;

  const QuickLink({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.url,
    this.onTap,
  });
}