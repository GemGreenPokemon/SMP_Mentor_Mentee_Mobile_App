import 'package:flutter/material.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;
  final String? route;
  final VoidCallback? onTap;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
    this.route,
    this.onTap,
  });
}