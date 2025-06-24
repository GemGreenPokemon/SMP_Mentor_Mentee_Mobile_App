import 'package:flutter/material.dart';

class SettingsCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color? color;
  final List<String> sectionIds;
  final bool requiresAuth;
  final List<String> allowedRoles;

  const SettingsCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
    required this.sectionIds,
    this.requiresAuth = false,
    this.allowedRoles = const [],
  });

  bool isAccessibleByRole(String? userRole) {
    if (allowedRoles.isEmpty) return true;
    if (userRole == null) return false;
    return allowedRoles.contains(userRole.toLowerCase());
  }
}

// Predefined categories
class SettingsCategories {
  static const general = SettingsCategory(
    id: 'general',
    name: 'General',
    icon: Icons.settings,
    sectionIds: ['overview', 'account', 'notifications', 'appearance'],
  );

  static const dataStorage = SettingsCategory(
    id: 'data_storage',
    name: 'Data & Storage',
    icon: Icons.storage,
    sectionIds: ['file_storage', 'data_management'],
  );

  static const administration = SettingsCategory(
    id: 'administration',
    name: 'Administration',
    icon: Icons.admin_panel_settings,
    color: Colors.orange,
    sectionIds: ['user_management', 'database_admin', 'developer_tools'],
    requiresAuth: true,
    allowedRoles: ['developer', 'super_admin', 'coordinator'],
  );

  static const support = SettingsCategory(
    id: 'support',
    name: 'Support',
    icon: Icons.help_outline,
    sectionIds: ['help_support', 'about'],
  );

  static List<SettingsCategory> all = [
    general,
    dataStorage,
    administration,
    support,
  ];

  static SettingsCategory? findById(String id) {
    return all.firstWhere(
      (category) => category.id == id,
      orElse: () => general,
    );
  }

  static List<SettingsCategory> getAccessibleCategories(String? userRole) {
    return all.where((category) => category.isAccessibleByRole(userRole)).toList();
  }
}