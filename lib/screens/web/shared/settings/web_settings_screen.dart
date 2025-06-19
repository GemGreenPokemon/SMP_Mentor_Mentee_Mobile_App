import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import '../../../../utils/developer_session.dart';
import '../../../../utils/responsive.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/cloud_function_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/direct_database_service.dart';
import '../../../../services/real_time_user_service.dart';
import '../../../../models/user.dart';
import 'sections/notification_settings_section.dart';
import 'sections/appearance_settings_section.dart';
import 'sections/file_storage_settings_section.dart';
import 'sections/account_settings_section.dart';
import 'sections/excel_upload_section.dart';
import 'sections/user_management_section.dart';
import 'sections/database_admin_section.dart';
import 'sections/help_support_section.dart';
import 'sections/developer_tools_section.dart';
import 'widgets/auth_overlay.dart';
import 'dialogs/database_initialization_choice_dialog.dart';
import 'dialogs/firestore_initializer_dialog.dart';
import 'dialogs/cloud_function_initializer_dialog.dart';

class WebSettingsScreen extends StatefulWidget {
  final bool isMentor;
  const WebSettingsScreen({super.key, this.isMentor = true});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
  // Basic settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _downloadLocation = 'Default Downloads Folder';
  
  // Auth overlay state
  bool _showAuthOverlayFlag = false;
  bool _isAuthenticated = false;
  Function()? _pendingAuthAction;
  
  // User management variables
  List<User> _usersList = [];
  bool _loadingUsers = false;
  bool _showAddUserForm = false;
  bool _showEditUserForm = false;
  User? _editingUser;
  bool _hasCheckedAuth = false;
  
  // Services
  final AuthService _authService = AuthService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  StreamSubscription<List<User>>? _usersStreamSubscription;
  
  // Firestore initializer variables
  String _selectedState = 'California';
  String _selectedCity = 'Merced';
  String _selectedCampus = 'UC_Merced';
  bool _isInitializing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DeveloperSession.isActive && !_hasCheckedAuth) {
      _hasCheckedAuth = true;
      _checkAuthAndLoadUsers();
    }
  }

  @override
  void dispose() {
    // Clean up real-time subscriptions
    _usersStreamSubscription?.cancel();
    _realTimeUserService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    double contentMaxWidth = isDesktop ? 800 : (isTablet ? 600 : double.infinity);

    return Stack(
      children: [
        // Main settings screen
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: const Color(0xFF0F2D52),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    if (DeveloperSession.isActive) {
                      Navigator.pushReplacementNamed(context, '/dev');
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  }
                });
              },
            ),
          ),
          body: IgnorePointer(
            ignoring: _showAuthOverlayFlag,
            child: AnimatedOpacity(
              opacity: _showAuthOverlayFlag ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 24,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        // Notifications Section
                        NotificationSettingsSection(
                          notificationsEnabled: _notificationsEnabled,
                          emailNotifications: _emailNotifications,
                          onNotificationsChanged: (value) => setState(() => _notificationsEnabled = value),
                          onEmailNotificationsChanged: (value) => setState(() => _emailNotifications = value),
                        ),
                        const SizedBox(height: 24),
                        
                        // Appearance Section
                        AppearanceSettingsSection(
                          darkMode: _darkMode,
                          language: _language,
                          onDarkModeChanged: (value) => setState(() => _darkMode = value),
                          onLanguagePressed: () => _showLanguageDialog(),
                        ),
                        const SizedBox(height: 24),
                        
                        // File Storage Section
                        FileStorageSettingsSection(
                          downloadLocation: _downloadLocation,
                          onDownloadLocationPressed: () => _showDownloadLocationDialog(),
                          onClearCachePressed: () => _showClearCacheDialog(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Account Settings Section
                        const AccountSettingsSection(),
                        const SizedBox(height: 24),
                        
                        // Data Management Section (Excel Upload)
                        const ExcelUploadSection(),
                        const SizedBox(height: 24),
                        
                        // Developer-only sections
                        if (DeveloperSession.isActive) ...[
                          // User Management Section
                          UserManagementSection(
                            usersList: _usersList,
                            loadingUsers: _loadingUsers,
                            showAddUserForm: _showAddUserForm,
                            showEditUserForm: _showEditUserForm,
                            editingUser: _editingUser,
                            onToggleAddUserForm: () => _toggleAddUserForm(),
                            onToggleEditUserForm: (user) => _editUser(user),
                            onCancelEdit: () => _cancelEdit(),
                            onCreateUser: _createUser,
                            onUpdateUser: _updateUser,
                            onDeleteUser: _deleteUser,
                            onShowAuthOverlay: _showAuthOverlay,
                            isAuthenticated: _isAuthenticated,
                            authService: _authService,
                          ),
                          const SizedBox(height: 24),
                          
                          // Database Administration Section
                          DatabaseAdminSection(
                            onInitializeDatabase: _handleDatabaseInitialization,
                          ),
                          const SizedBox(height: 24),
                          
                          // Developer Tools Section
                          const DeveloperToolsSection(),
                          const SizedBox(height: 24),
                        ],
                        
                        // Help & Support Section
                        const HelpSupportSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Auth overlay
        if (_showAuthOverlayFlag)
          AuthOverlay(
            onAuthSuccess: () {
              setState(() {
                _isAuthenticated = true;
                _showAuthOverlayFlag = false;
              });
              
              if (_pendingAuthAction != null) {
                _pendingAuthAction!();
                _pendingAuthAction = null;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged in successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onCancel: () {
              setState(() {
                _showAuthOverlayFlag = false;
                _pendingAuthAction = null;
              });
            },
          ),
      ],
    );
  }


  // Dialog methods (simplified versions for now)
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: _language == 'Spanish' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'Spanish';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: _language == 'French' ? const Icon(Icons.check, color: Color(0xFF0F2D52)) : null,
              onTap: () {
                setState(() {
                  _language = 'French';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Download Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Default Downloads Folder'),
              trailing: _downloadLocation == 'Default Downloads Folder'
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Default Downloads Folder';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Documents Folder'),
              trailing: _downloadLocation == 'Documents Folder'
                  ? const Icon(Icons.check, color: Color(0xFF0F2D52))
                  : null,
              onTap: () {
                setState(() {
                  _downloadLocation = 'Documents Folder';
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Custom Location...'),
              trailing: const Icon(Icons.folder),
              onTap: () {
                // TODO: Implement custom location picker
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will free up space by removing cached data. Your saved files and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  // Show auth overlay
  void _showAuthOverlay({Function()? onSuccess}) {
    setState(() {
      _showAuthOverlayFlag = true;
      _pendingAuthAction = onSuccess;
    });
  }
  
  // Check if authenticated
  bool _requiresAuth() {
    return !_isAuthenticated && !_authService.isLoggedIn;
  }

  // Check authentication and load users
  Future<void> _checkAuthAndLoadUsers() async {
    if (!mounted) return;
    
    // Check if user is authenticated
    if (_requiresAuth()) {
      _showAuthOverlay(onSuccess: () async {
        await _loadUsers();
      });
      return;
    }

    // Check if user has coordinator permissions
    final isCoordinator = await _authService.isSuperAdmin(); // Using super admin for now
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

  // Load users from database
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
    if (_showAddUserForm) {
      setState(() => _showAddUserForm = false);
    } else {
      // Check authentication before showing form
      if (_requiresAuth()) {
        _showAuthOverlay(onSuccess: () {
          setState(() => _showAddUserForm = true);
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
      setState(() => _showAddUserForm = true);
    }
  }

  void _editUser(User user) {
    setState(() {
      _editingUser = user;
      _showEditUserForm = true;
      _showAddUserForm = false; // Close add form if open
    });
  }

  void _cancelEdit() {
    setState(() {
      _showEditUserForm = false;
      _editingUser = null;
    });
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
            Text('Are you sure you want to delete this user?'),
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
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Use addPostFrameCallback to avoid Navigator re-entrance
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              
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

  // Helper methods for campus selection
  void _updateCampusSelection(String city) {
    switch (city) {
      case 'Merced':
        _selectedCampus = 'UC_Merced';
        break;
      case 'Fresno':
        _selectedCampus = 'Fresno_State';
        break;
      case 'Berkeley':
        _selectedCampus = 'UC_Berkeley';
        break;
      case 'Los Angeles':
        _selectedCampus = 'UCLA';
        break;
    }
  }

  List<Map<String, String>> _getCampusOptions(String city) {
    switch (city) {
      case 'Merced':
        return [
          {'value': 'UC_Merced', 'display': 'UC Merced', 'name': 'University of California, Merced'},
          {'value': 'Merced_College', 'display': 'Merced College', 'name': 'Merced College'},
        ];
      case 'Fresno':
        return [
          {'value': 'Fresno_State', 'display': 'Fresno State', 'name': 'California State University, Fresno'},
          {'value': 'Fresno_City_College', 'display': 'Fresno City College', 'name': 'Fresno City College'},
        ];
      case 'Berkeley':
        return [
          {'value': 'UC_Berkeley', 'display': 'UC Berkeley', 'name': 'University of California, Berkeley'},
          {'value': 'Berkeley_City_College', 'display': 'Berkeley City College', 'name': 'Berkeley City College'},
        ];
      case 'Los Angeles':
        return [
          {'value': 'UCLA', 'display': 'UCLA', 'name': 'University of California, Los Angeles'},
          {'value': 'USC', 'display': 'USC', 'name': 'University of Southern California'},
          {'value': 'LA_City_College', 'display': 'LA City College', 'name': 'Los Angeles City College'},
        ];
      default:
        return [];
    }
  }

  // Handle database initialization with Cloud Functions
  Future<void> _handleDatabaseInitialization() async {
    // Show options dialog - Cloud Function vs Direct (for testing)
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => const DatabaseInitializationChoiceDialog(),
    );

    if (choice == 'cloud') {
      await _handleCloudFunctionInit();
    } else if (choice == 'direct') {
      _showFirestoreInitializerDialog();
    }
  }

  // Handle Cloud Function initialization with authentication
  Future<void> _handleCloudFunctionInit() async {
    // Check if user is authenticated
    if (_requiresAuth()) {
      _showAuthOverlay(onSuccess: () {
        _showCloudFunctionInitializerDialog();
      });
      return;
    }

    // Check if user has super admin permissions
    final isSuperAdmin = await _authService.isSuperAdmin();
    if (!isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super admin permissions required for database initialization'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with Cloud Function initialization
    _showCloudFunctionInitializerDialog();
  }

  void _showFirestoreInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FirestoreInitializerDialog(
        initialState: _selectedState,
        initialCity: _selectedCity,
        initialCampus: _selectedCampus,
        onStateChanged: (state) {
          setState(() {
            _selectedState = state;
          });
        },
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city;
            _updateCampusSelection(city);
          });
        },
        onCampusChanged: (campus) {
          setState(() {
            _selectedCampus = campus;
          });
        },
      ),
    );
  }

  void _showCloudFunctionInitializerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloudFunctionInitializerDialog(
        initialState: _selectedState,
        initialCity: _selectedCity,
        initialCampus: _selectedCampus,
        cloudFunctions: _cloudFunctions,
        onStateChanged: (state) {
          setState(() {
            _selectedState = state;
          });
        },
        onCityChanged: (city) {
          setState(() {
            _selectedCity = city;
            _updateCampusSelection(city);
          });
        },
        onCampusChanged: (campus) {
          setState(() {
            _selectedCampus = campus;
          });
        },
      ),
    );
  }
}