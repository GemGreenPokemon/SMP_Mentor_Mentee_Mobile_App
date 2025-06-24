import 'package:flutter/material.dart';
import '../models/settings_navigation_item.dart';
import '../models/settings_category.dart';

class SettingsHelpers {
  // Generate navigation items based on user role
  static List<SettingsNavigationItem> generateNavigationItems(String? userRole) {
    final List<SettingsNavigationItem> items = [];
    
    // General category
    items.add(SettingsNavigationItem.header('GENERAL'));
    items.addAll(_getGeneralItems());
    
    // Data & Storage category
    items.add(SettingsNavigationItem.divider());
    items.add(SettingsNavigationItem.header('DATA & STORAGE'));
    items.addAll(_getDataStorageItems());
    
    // Administration category (role-based)
    if (_hasAdminAccess(userRole)) {
      items.add(SettingsNavigationItem.divider());
      items.add(SettingsNavigationItem.header('ADMINISTRATION'));
      items.addAll(_getAdminItems(userRole));
    }
    
    // Support category
    items.add(SettingsNavigationItem.divider());
    items.add(SettingsNavigationItem.header('SUPPORT'));
    items.addAll(_getSupportItems());
    
    return items;
  }

  static List<SettingsNavigationItem> _getGeneralItems() {
    return [
      const SettingsNavigationItem(
        id: 'overview',
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        route: '/settings/overview',
      ),
      const SettingsNavigationItem(
        id: 'account',
        label: 'Account',
        icon: Icons.person_outline,
        route: '/settings/account',
      ),
      const SettingsNavigationItem(
        id: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        route: '/settings/notifications',
      ),
      const SettingsNavigationItem(
        id: 'appearance',
        label: 'Appearance',
        icon: Icons.palette_outlined,
        route: '/settings/appearance',
      ),
    ];
  }

  static List<SettingsNavigationItem> _getDataStorageItems() {
    return [
      const SettingsNavigationItem(
        id: 'file_storage',
        label: 'File Storage',
        icon: Icons.folder_outlined,
        route: '/settings/storage',
      ),
      const SettingsNavigationItem(
        id: 'data_management',
        label: 'Data Import/Export',
        icon: Icons.import_export,
        route: '/settings/data',
      ),
    ];
  }

  static List<SettingsNavigationItem> _getAdminItems(String? userRole) {
    final items = <SettingsNavigationItem>[];
    
    // User management for coordinators and above
    if (_hasCoordinatorAccess(userRole)) {
      items.add(const SettingsNavigationItem(
        id: 'user_management',
        label: 'User Management',
        icon: Icons.group_outlined,
        route: '/settings/users',
        requiresAuth: true,
        allowedRoles: ['coordinator', 'developer', 'super_admin'],
      ));
    }
    
    // Developer tools for developers only
    if (_hasDeveloperAccess(userRole)) {
      items.addAll([
        const SettingsNavigationItem(
          id: 'database_admin',
          label: 'Database Admin',
          icon: Icons.storage_outlined,
          route: '/settings/database',
          requiresAuth: true,
          allowedRoles: ['developer', 'super_admin'],
        ),
        const SettingsNavigationItem(
          id: 'developer_tools',
          label: 'Developer Tools',
          icon: Icons.code,
          route: '/settings/developer',
          requiresAuth: true,
          allowedRoles: ['developer', 'super_admin'],
        ),
      ]);
    }
    
    return items;
  }

  static List<SettingsNavigationItem> _getSupportItems() {
    return [
      const SettingsNavigationItem(
        id: 'help_support',
        label: 'Help & Resources',
        icon: Icons.help_outline,
        route: '/settings/help',
      ),
      const SettingsNavigationItem(
        id: 'about',
        label: 'About',
        icon: Icons.info_outline,
        route: '/settings/about',
      ),
    ];
  }

  // Role checking helpers
  static bool _hasAdminAccess(String? role) {
    if (role == null) return false;
    final lowerRole = role.toLowerCase();
    return lowerRole == 'developer' || 
           lowerRole == 'super_admin' || 
           lowerRole == 'coordinator';
  }

  static bool _hasCoordinatorAccess(String? role) {
    if (role == null) return false;
    final lowerRole = role.toLowerCase();
    return lowerRole == 'coordinator' || 
           lowerRole == 'developer' || 
           lowerRole == 'super_admin';
  }

  static bool _hasDeveloperAccess(String? role) {
    if (role == null) return false;
    final lowerRole = role.toLowerCase();
    return lowerRole == 'developer' || lowerRole == 'super_admin';
  }

  // Get item by route
  static SettingsNavigationItem? getItemByRoute(
    String route,
    List<SettingsNavigationItem> items,
  ) {
    try {
      return items.firstWhere(
        (item) => item.route == route && item.isClickable,
      );
    } catch (_) {
      return null;
    }
  }

  // Get item index by ID
  static int getItemIndexById(String id, List<SettingsNavigationItem> items) {
    final clickableItems = items.where((item) => item.isClickable).toList();
    return clickableItems.indexWhere((item) => item.id == id);
  }

  // Format setting value for display
  static String formatSettingValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is bool) return value ? 'Enabled' : 'Disabled';
    if (value is List) return '${value.length} items';
    if (value is Map) return '${value.length} entries';
    return value.toString();
  }

  // Get icon for setting type
  static IconData getSettingTypeIcon(dynamic value) {
    if (value is bool) return Icons.toggle_on;
    if (value is String) return Icons.text_fields;
    if (value is num) return Icons.numbers;
    if (value is List) return Icons.list;
    if (value is Map) return Icons.dataset;
    return Icons.settings;
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get relative time string
  static String getRelativeTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}