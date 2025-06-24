import 'package:flutter/material.dart';
import 'dart:async';
import '../../web_settings/sections/user_management_section_v2.dart';
import '../utils/settings_constants.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/cloud_function_service.dart';
import '../../../../../services/real_time_user_service.dart';
import '../../../../../models/user.dart';

class UserManagementView extends StatefulWidget {
  final Function({Function()? onSuccess}) onShowAuthOverlay;
  final bool isAuthenticated;
  
  const UserManagementView({
    super.key,
    required this.onShowAuthOverlay,
    required this.isAuthenticated,
  });

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  // User management variables
  List<User> _usersList = [];
  bool _loadingUsers = false;
  bool _hasCheckedAuth = false;
  
  // Services
  final AuthService _authService = AuthService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  StreamSubscription<List<User>>? _usersStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadUsers();
  }

  @override
  void dispose() {
    _usersStreamSubscription?.cancel();
    _realTimeUserService.stopListening();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadUsers() async {
    if (!mounted) return;
    
    // Check if user is authenticated
    if (_requiresAuth()) {
      widget.onShowAuthOverlay(onSuccess: () async {
        await _loadUsers();
      });
      return;
    }

    // Check if user has coordinator permissions
    final isCoordinator = await _authService.isSuperAdmin();
    if (!isCoordinator) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coordinator permissions required for user management'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Load users if authenticated
    await _loadUsers();
  }

  bool _requiresAuth() {
    return !widget.isAuthenticated && !_authService.isLoggedIn;
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _loadingUsers = true;
      });
    }

    try {
      final universityPath = _cloudFunctions.getCurrentUniversityPath();
      
      // Cancel any existing subscription
      await _usersStreamSubscription?.cancel();
      
      // Start listening to real-time updates
      _realTimeUserService.startListening(universityPath);
      
      // Subscribe to user updates
      _usersStreamSubscription = _realTimeUserService.usersStream.listen(
        (List<User> users) {
          if (mounted) {
            setState(() {
              _usersList = users;
              _loadingUsers = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _loadingUsers = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Real-time error: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
      
      // If we already have cached users, show them immediately
      final cachedUsers = _realTimeUserService.currentUsers;
      if (cachedUsers.isNotEmpty && mounted) {
        setState(() {
          _usersList = cachedUsers;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usersList = [];
          _loadingUsers = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting real-time updates: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleAddUserForm() async {
    // Check authentication before allowing form
    if (_requiresAuth()) {
      widget.onShowAuthOverlay(onSuccess: () {
        // Auth success - the V2 component will handle showing the dialog
      });
      return;
    }
    final isCoordinator = await _authService.isSuperAdmin();
    if (!isCoordinator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinator permissions required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Permission granted - the V2 component will handle showing the dialog
  }

  void _editUser(User user) {
    // The V2 component handles showing the edit dialog
  }

  void _cancelEdit() {
    // The V2 component handles closing dialogs
  }

  Future<void> _createUser({
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentor,
  }) async {
    final universityPath = _cloudFunctions.getCurrentUniversityPath();
    
    // Create the user first
    final result = await _cloudFunctions.createUserAccount(
      universityPath: universityPath,
      name: name,
      email: email,
      userType: userType,
      studentId: studentId,
      department: department,
      yearMajor: yearMajor,
      acknowledgmentSigned: acknowledgmentSigned,
    );

    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to create user');
    }

    // If this is a mentee and mentor is assigned, create mentorship
    if (userType == 'mentee' && mentor != null && result['data'] != null) {
      try {
        final newUserId = result['data']['id'];
        await _cloudFunctions.assignMentor(
          universityPath: universityPath,
          mentorId: mentor,
          menteeId: newUserId,
        );
      } catch (e) {
        // Log the error but don't fail the user creation
        print('Warning: Failed to assign mentor: $e');
      }
    }
  }

  Future<void> _updateUser({
    required String userId,
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentorId,
  }) async {
    final universityPath = _cloudFunctions.getCurrentUniversityPath();
    
    // Use the real-time service to update the user directly in Firestore
    final updateData = <String, dynamic>{
      'name': name,
      'email': email,
      'userType': userType,
      'acknowledgment_signed': acknowledgmentSigned,
    };
    
    // Add optional fields only if they have values
    if (studentId != null && studentId.isNotEmpty) {
      updateData['student_id'] = studentId;
    }
    if (department != null && department.isNotEmpty) {
      updateData['department'] = department;
    }
    if (yearMajor != null && yearMajor.isNotEmpty) {
      updateData['year_major'] = yearMajor;
    }
    
    // Handle mentor assignment for mentees
    if (userType == 'mentee') {
      updateData['mentor'] = mentorId; // Can be null to unassign
    }
    
    // Update the user using the real-time service
    final success = await _realTimeUserService.updateUser(
      universityPath,
      userId,
      updateData,
    );
    
    if (!success) {
      throw Exception('Failed to update user in database');
    }
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this user?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(user.email),
                  Text('Type: ${user.userType}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final universityPath = _cloudFunctions.getCurrentUniversityPath();
                final result = await _cloudFunctions.deleteUserAccount(
                  universityPath: universityPath,
                  userId: user.id,
                );

                if (result['success'] == true) {
                  await _loadUsers(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  throw Exception(result['message'] ?? 'Failed to delete user');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < SettingsDashboardConstants.mobileBreakpoint;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile
            ? SettingsDashboardConstants.compactPadding
            : SettingsDashboardConstants.defaultPadding,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: UserManagementSectionV2(
            usersList: _usersList,
            loadingUsers: _loadingUsers,
            onToggleAddUserForm: _toggleAddUserForm,
            onToggleEditUserForm: _editUser,
            onCancelEdit: _cancelEdit,
            onCreateUser: _createUser,
            onUpdateUser: _updateUser,
            onDeleteUser: _deleteUser,
            onShowAuthOverlay: widget.onShowAuthOverlay,
            isAuthenticated: widget.isAuthenticated,
            authService: _authService,
          ),
        ),
      ),
    );
  }
}