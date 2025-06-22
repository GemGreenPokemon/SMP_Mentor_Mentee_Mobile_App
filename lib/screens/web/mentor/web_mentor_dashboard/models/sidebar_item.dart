import 'package:flutter/material.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}

class SidebarItems {
  static const List<String> titles = [
    'Dashboard',
    'Mentees',
    'Messages',
    'Schedule',
    'Reports',
    'Resources',
    'Checklist',
    'Newsletters',
    'Announcements',
    'Settings',
  ];

  static const List<IconData> icons = [
    Icons.dashboard,
    Icons.people,
    Icons.chat,
    Icons.event_note,
    Icons.assessment,
    Icons.folder_open,
    Icons.check_circle_outline,
    Icons.newspaper,
    Icons.campaign,
    Icons.settings,
  ];

  static List<SidebarItem> get items {
    return List.generate(
      titles.length,
      (index) => SidebarItem(
        title: titles[index],
        icon: icons[index],
        index: index,
      ),
    );
  }

  static String getPageDescription(int index) {
    final descriptions = [
      'Overview of your mentorship activities',
      'Manage and connect with your mentees',
      'Send and receive messages',
      'Schedule and manage meetings',
      'Track progress and submit reports',
      'Access helpful resources and materials',
      'Track your mentorship checklist',
      'Stay updated with program newsletters',
      'View important announcements',
      'Manage your account settings',
    ];
    return index < descriptions.length ? descriptions[index] : '';
  }
}