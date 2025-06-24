import 'package:flutter/material.dart';

class SettingsNavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String? route;
  final bool requiresAuth;
  final List<String> allowedRoles;
  final Widget Function()? contentBuilder;
  final bool isDivider;
  final bool isHeader;
  final String? category;

  const SettingsNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.requiresAuth = false,
    this.allowedRoles = const [],
    this.contentBuilder,
    this.isDivider = false,
    this.isHeader = false,
    this.category,
  });

  factory SettingsNavigationItem.divider() {
    return const SettingsNavigationItem(
      id: 'divider',
      label: '',
      icon: Icons.remove,
      isDivider: true,
    );
  }

  factory SettingsNavigationItem.header(String label) {
    return SettingsNavigationItem(
      id: 'header_$label',
      label: label,
      icon: Icons.label,
      isHeader: true,
    );
  }

  bool get isClickable => !isDivider && !isHeader;

  bool isAccessibleByRole(String? userRole) {
    if (allowedRoles.isEmpty) return true;
    if (userRole == null) return false;
    return allowedRoles.contains(userRole.toLowerCase());
  }
}