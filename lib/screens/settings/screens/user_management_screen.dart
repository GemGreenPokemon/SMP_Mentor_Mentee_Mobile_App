import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/auth_service.dart';
import '../../../services/cloud_function_service.dart';
import '../../../services/real_time_user_service.dart';
import '../../../models/user.dart';
import '../../../utils/responsive.dart';
import '../widgets/auth_overlay.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final AuthService _authService = AuthService();
  final RealTimeUserService _realTimeUserService = RealTimeUserService();
  
  // User management variables
  List<User> _usersList = [];
  bool _loadingUsers = false;
  bool _showAddUserForm = false;
  bool _showEditUserForm = false;
  User? _editingUser;
  bool _hasCheckedAuth = false;
  
  // Real-time user service
  StreamSubscription<List<User>>? _usersStreamSubscription;
  
  // Auth overlay variables
  bool _showAuthOverlayFlag = false;
  bool _isAuthenticated = false;
  Function()? _pendingAuthAction;

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('User Management'),
            backgroundColor: const Color(0xFF0F2D52),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: IgnorePointer(
            ignoring: _showAuthOverlayFlag,
            child: AnimatedOpacity(
              opacity: _showAuthOverlayFlag ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Authorized Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F2D52),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_showAddUserForm) {
                              setState(() => _showAddUserForm = false);
                            } else {
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
                          },
                          icon: Icon(_showAddUserForm ? Icons.close : Icons.person_add),
                          label: Text(_showAddUserForm ? 'Cancel' : 'Add User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2D52),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Add user form
                    if (_showAddUserForm) ...[
                      _buildAddUserForm(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Edit user form
                    if (_showEditUserForm && _editingUser != null) ...[
                      _buildEditUserForm(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Users list
                    Expanded(child: _buildUsersList()),
                  ],
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

  Widget _buildAddUserForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final studentIdController = TextEditingController();
    final departmentController = TextEditingController();
    final yearMajorController = TextEditingController();
    String selectedUserType = 'mentee';
    String selectedAcknowledgment = 'not_applicable';
    String? selectedMentor;
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setFormState) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2D52),
              ),
            ),
            const SizedBox(height: 16),
            
            // Form fields with responsive layout
            Column(
              children: [
                // Row 1: Name and Email
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Row 2: Student ID and User Type
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUserType,
                          decoration: const InputDecoration(
                            labelText: 'User Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                            DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                            DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                          ],
                          onChanged: (value) {
                            setFormState(() {
                              selectedUserType = value!;
                              if (selectedUserType != 'mentee') {
                                selectedAcknowledgment = 'not_applicable';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'User Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                          DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                          DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                        ],
                        onChanged: (value) {
                          setFormState(() {
                            selectedUserType = value!;
                            if (selectedUserType != 'mentee') {
                              selectedAcknowledgment = 'not_applicable';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Row 3: Department and Year/Major
                Responsive.isDesktop(context) 
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: yearMajorController,
                          decoration: const InputDecoration(
                            labelText: 'Year & Major',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grade),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: yearMajorController,
                        decoration: const InputDecoration(
                          labelText: 'Year & Major',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Conditional fields based on user type
            if (selectedUserType == 'mentee') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedAcknowledgment,
                      decoration: const InputDecoration(
                        labelText: 'Acknowledgment Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'yes', child: Text('Signed')),
                        DropdownMenuItem(value: 'no', child: Text('Not Signed')),
                        DropdownMenuItem(value: 'not_applicable', child: Text('Not Applicable')),
                      ],
                      onChanged: (value) {
                        setFormState(() {
                          selectedAcknowledgment = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: selectedMentor,
                      decoration: const InputDecoration(
                        labelText: 'Assign Mentor (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.supervisor_account),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Mentor Assigned')),
                        ..._usersList
                            .where((user) => user.userType == 'mentor')
                            .map((mentor) => DropdownMenuItem(
                                  value: mentor.studentId ?? mentor.id,
                                  child: Text(
                                    mentor.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                      ],
                      onChanged: (value) {
                        setFormState(() {
                          selectedMentor = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Submit button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSubmitting ? null : () {
                    nameController.clear();
                    emailController.clear();
                    studentIdController.clear();
                    departmentController.clear();
                    yearMajorController.clear();
                    setState(() => _showAddUserForm = false);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.trim().isEmpty || 
                        emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Email are required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setFormState(() => isSubmitting = true);

                    try {
                      await _createUser(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        userType: selectedUserType,
                        studentId: studentIdController.text.trim().isEmpty 
                            ? null : studentIdController.text.trim(),
                        department: departmentController.text.trim().isEmpty 
                            ? null : departmentController.text.trim(),
                        yearMajor: yearMajorController.text.trim().isEmpty 
                            ? null : yearMajorController.text.trim(),
                        acknowledgmentSigned: selectedAcknowledgment,
                        mentor: selectedMentor,
                      );

                      nameController.clear();
                      emailController.clear();
                      studentIdController.clear();
                      departmentController.clear();
                      yearMajorController.clear();
                      if (mounted) setState(() => _showAddUserForm = false);
                      
                      await _loadUsers();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding user: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setFormState(() => isSubmitting = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2D52),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditUserForm() {
    // Implementation similar to add form but with pre-populated data
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Text(
        'Edit User Form - TODO: Extract from original file',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_loadingUsers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_usersList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add users manually or upload an Excel file to get started',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                SizedBox(width: 12),
                Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                SizedBox(width: 12),
                Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                SizedBox(width: 16),
                Expanded(flex: 2, child: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                SizedBox(width: 12),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                SizedBox(width: 12),
                SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          ),
          
          // User rows
          Expanded(
            child: ListView.builder(
              itemCount: _usersList.length,
              itemBuilder: (context, index) {
                final user = _usersList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.white : Colors.grey[25],
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            if (user.studentId != null)
                              Text(
                                'ID: ${user.studentId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          user.email,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getUserTypeColor(user.userType),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.userType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          user.department ?? '-',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: _getStatusColor(user),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getStatusText(user),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(user),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _editUser(user),
                              tooltip: 'Edit User',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'mentor':
        return Colors.blue;
      case 'mentee':
        return Colors.green;
      case 'coordinator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(User user) {
    return Colors.orange; // For now, assume all are pending
  }

  String _getStatusText(User user) {
    return 'Pending'; // For now, assume all are pending
  }

  // Auth and user management methods
  void _showAuthOverlay({Function()? onSuccess}) {
    setState(() {
      _showAuthOverlayFlag = true;
      _pendingAuthAction = onSuccess;
    });
  }
  
  bool _requiresAuth() {
    return !_isAuthenticated && !_authService.isLoggedIn;
  }

  Future<void> _checkAuthAndLoadUsers() async {
    if (!mounted) return;
    
    if (_requiresAuth()) {
      _showAuthOverlay(onSuccess: () async {
        await _loadUsers();
      });
      return;
    }

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

    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _loadingUsers = true;
      });
    }

    try {
      final universityPath = _cloudFunctions.getCurrentUniversityPath();
      
      await _usersStreamSubscription?.cancel();
      
      _realTimeUserService.startListening(universityPath);
      
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

    if (userType == 'mentee' && mentor != null && result['data'] != null) {
      try {
        final newUserId = result['data']['id'];
        await _cloudFunctions.assignMentor(
          universityPath: universityPath,
          mentorId: mentor,
          menteeId: newUserId,
        );
      } catch (e) {
        print('Warning: Failed to assign mentor: $e');
      }
    }
  }

  void _editUser(User user) {
    setState(() {
      _editingUser = user;
      _showEditUserForm = true;
      _showAddUserForm = false;
    });
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
                  await _loadUsers();
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
}