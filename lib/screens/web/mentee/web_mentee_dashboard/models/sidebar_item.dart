import 'package:flutter/material.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badge;
  final Color? badgeColor;

  const SidebarItem({
    required this.title,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.badgeColor,
  });
}

class SidebarItems {
  static const List<SidebarItem> items = [
    SidebarItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    SidebarItem(
      title: 'Schedule',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
    ),
    SidebarItem(
      title: 'Resources',
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_open,
    ),
    SidebarItem(
      title: 'Checklist',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    SidebarItem(
      title: 'Meeting Notes',
      icon: Icons.note_alt_outlined,
      selectedIcon: Icons.note_alt,
    ),
    SidebarItem(
      title: 'Newsletters',
      icon: Icons.newspaper_outlined,
      selectedIcon: Icons.newspaper,
    ),
    SidebarItem(
      title: 'Announcements',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    SidebarItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}