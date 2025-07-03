import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import '../models/user_filter.dart';
import '../models/import_preview_data.dart';
import 'user_management_constants.dart';

class UserManagementHelpers {
  // Filter users based on current filter settings
  static List<User> filterUsers(List<User> users, UserFilter filter) {
    return users.where((user) {
      // Type filter
      if (filter.typeFilter != UserTypeFilter.all) {
        switch (filter.typeFilter) {
          case UserTypeFilter.mentee:
            if (user.userType != 'mentee') return false;
            break;
          case UserTypeFilter.mentor:
            if (user.userType != 'mentor') return false;
            break;
          case UserTypeFilter.coordinator:
            if (user.userType != 'coordinator') return false;
            break;
          default:
            break;
        }
      }

      // Status filter
      if (filter.statusFilter != UserStatusFilter.all) {
        switch (filter.statusFilter) {
          case UserStatusFilter.acknowledged:
            if (user.acknowledgmentSigned == 'not_applicable' || 
                user.acknowledgmentSigned == 'No') return false;
            break;
          case UserStatusFilter.notAcknowledged:
            if (user.acknowledgmentSigned != 'not_applicable' && 
                user.acknowledgmentSigned != 'No') return false;
            break;
          case UserStatusFilter.pendingVerification:
            // Add logic for pending verification if needed
            break;
          default:
            break;
        }
      }

      // Mentor assignment filter for mentees
      if (user.userType == 'mentee') {
        if (filter.showOnlyWithMentors && (user.mentor == null || user.mentor!.isEmpty)) {
          return false;
        }
        if (filter.showOnlyWithoutMentors && user.mentor != null && user.mentor!.isNotEmpty) {
          return false;
        }
      }

      // Search query
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesName = user.name.toLowerCase().contains(query);
        final matchesEmail = user.email.toLowerCase().contains(query);
        final matchesStudentId = user.studentId?.toLowerCase().contains(query) ?? false;
        
        if (!matchesName && !matchesEmail && !matchesStudentId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Get user type color
  static Color getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'mentee':
        return UserManagementConstants.menteeColor;
      case 'mentor':
        return UserManagementConstants.mentorColor;
      case 'coordinator':
        return UserManagementConstants.coordinatorColor;
      default:
        return Colors.grey;
    }
  }

  // Get user type icon
  static IconData getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'mentee':
        return UserManagementConstants.menteeIcon;
      case 'mentor':
        return UserManagementConstants.mentorIcon;
      case 'coordinator':
        return UserManagementConstants.coordinatorIcon;
      default:
        return Icons.person;
    }
  }

  // Format user display name with type
  static String formatUserDisplay(User user) {
    return '${user.name} (${user.userType})';
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate student ID format
  static bool isValidStudentId(String studentId) {
    return studentId.isNotEmpty && studentId.length >= 6;
  }

  // Get status chip color
  static Color getStatusColor(User user) {
    if (user.acknowledgmentSigned != 'not_applicable' && 
        user.acknowledgmentSigned != 'No') {
      return UserManagementConstants.successColor;
    } else {
      return UserManagementConstants.warningColor;
    }
  }

  // Create summary statistics from import preview
  static Map<String, dynamic> getImportStatistics(ImportPreviewData preview) {
    return {
      'Total Users': preview.totalUsers,
      'Mentors': preview.mentorsCount,
      'Mentees': preview.menteesCount,
      'Existing Users': preview.existingUsersCount,
      'New Users': preview.totalUsers - preview.existingUsersCount,
      'Errors': preview.errors.length,
      'Warnings': preview.warnings.length,
    };
  }

  // Generate placeholder email if needed
  static String generatePlaceholderEmail(String name, String userType) {
    final cleanName = name.toLowerCase().replaceAll(' ', '.');
    return '$cleanName.$userType@ucmerced.edu';
  }

  // Sort users by various criteria
  static List<User> sortUsers(List<User> users, String sortBy, bool ascending) {
    final sorted = List<User>.from(users);
    
    switch (sortBy) {
      case 'name':
        sorted.sort((a, b) => ascending 
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
        break;
      case 'email':
        sorted.sort((a, b) => ascending
          ? a.email.compareTo(b.email)
          : b.email.compareTo(a.email));
        break;
      case 'type':
        sorted.sort((a, b) => ascending
          ? a.userType.compareTo(b.userType)
          : b.userType.compareTo(a.userType));
        break;
      case 'status':
        sorted.sort((a, b) {
          final aAcknowledged = a.acknowledgmentSigned != 'not_applicable' && 
                               a.acknowledgmentSigned != 'No';
          final bAcknowledged = b.acknowledgmentSigned != 'not_applicable' && 
                               b.acknowledgmentSigned != 'No';
          return ascending
            ? (aAcknowledged ? 1 : 0).compareTo(bAcknowledged ? 1 : 0)
            : (bAcknowledged ? 1 : 0).compareTo(aAcknowledged ? 1 : 0);
        });
        break;
    }
    
    return sorted;
  }
}