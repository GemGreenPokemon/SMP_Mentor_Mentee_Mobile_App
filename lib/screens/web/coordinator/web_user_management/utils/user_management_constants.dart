import 'package:flutter/material.dart';

class UserManagementConstants {
  // Screen titles and headers
  static const String screenTitle = 'User Management';
  static const String importSectionTitle = 'Import Users from Excel';
  static const String userListTitle = 'All Users';
  static const String addUserTitle = 'Add New User';
  static const String editUserTitle = 'Edit User';
  
  // Button labels
  static const String uploadButtonLabel = 'Upload Excel File';
  static const String importButtonLabel = 'Import Users';
  static const String cancelButtonLabel = 'Cancel';
  static const String saveButtonLabel = 'Save';
  static const String deleteButtonLabel = 'Delete';
  static const String addUserButtonLabel = 'Add User';
  static const String retryButtonLabel = 'Retry';
  static const String clearButtonLabel = 'Clear';
  
  // Tab labels
  static const String excelImportTab = 'Excel Import';
  static const String userListTab = 'User List';
  
  // Messages
  static const String noFileSelectedMessage = 'No file selected';
  static const String selectFileMessage = 'Please select an Excel file to import users';
  static const String processingMessage = 'Processing Excel file...';
  static const String importingMessage = 'Importing users...';
  static const String successMessage = 'Users imported successfully!';
  static const String errorMessage = 'An error occurred. Please try again.';
  static const String noUsersMessage = 'No users found';
  static const String deleteConfirmationMessage = 'Are you sure you want to delete this user?';
  
  // Validation messages
  static const String requiredFieldMessage = 'This field is required';
  static const String invalidEmailMessage = 'Please enter a valid email address';
  static const String invalidYearMessage = 'Please enter a valid year (1-4)';
  
  // Filter options
  static const Map<String, String> userTypeFilters = {
    'all': 'All Types',
    'mentee': 'Mentees',
    'mentor': 'Mentors',
    'coordinator': 'Coordinators',
  };
  
  static const Map<String, String> statusFilters = {
    'all': 'All Status',
    'acknowledged': 'Acknowledged',
    'notAcknowledged': 'Not Acknowledged',
    'pendingVerification': 'Pending Verification',
  };
  
  // Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE91E63);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color menteeColor = Color(0xFF2196F3);
  static const Color mentorColor = Color(0xFF4CAF50);
  static const Color coordinatorColor = Color(0xFF9C27B0);
  
  // Dimensions
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double dialogWidth = 600.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  
  // Icons
  static const IconData uploadIcon = Icons.upload_file;
  static const IconData importIcon = Icons.import_export;
  static const IconData addUserIcon = Icons.person_add;
  static const IconData editIcon = Icons.edit;
  static const IconData deleteIcon = Icons.delete;
  static const IconData searchIcon = Icons.search;
  static const IconData filterIcon = Icons.filter_list;
  static const IconData menteeIcon = Icons.school;
  static const IconData mentorIcon = Icons.supervisor_account;
  static const IconData coordinatorIcon = Icons.admin_panel_settings;
}