import 'package:flutter/material.dart';

class RoleSelection {
  final UserRole role;
  final IconData icon;
  
  RoleSelection({
    required this.role,
    required this.icon,
  });
}

enum UserRole {
  mentee,
  mentor,
  coordinator,
  developer,
}

class RoleConfig {
  static IconData getIcon(UserRole role) {
    switch (role) {
      case UserRole.mentee:
        return Icons.school;
      case UserRole.mentor:
        return Icons.psychology;
      case UserRole.coordinator:
        return Icons.admin_panel_settings;
      case UserRole.developer:
        return Icons.code;
    }
  }
  
  static String getTitle(UserRole role) {
    switch (role) {
      case UserRole.mentee:
        return 'Mentee';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.coordinator:
        return 'Coordinator';
      case UserRole.developer:
        return 'Developer';
    }
  }
  
  static String getDescription(UserRole role) {
    switch (role) {
      case UserRole.mentee:
        return 'Join as a student seeking guidance';
      case UserRole.mentor:
        return 'Join as someone who provides guidance';
      case UserRole.coordinator:
        return 'Join as a program administrator';
      case UserRole.developer:
        return 'Quick access for development testing';
    }
  }
}