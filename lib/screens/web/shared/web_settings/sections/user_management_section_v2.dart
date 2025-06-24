import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../../../../../models/user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../utils/responsive.dart';
import '../utils/settings_constants.dart';

class UserManagementSectionV2 extends StatefulWidget {
  final List<User> usersList;
  final bool loadingUsers;
  final VoidCallback onToggleAddUserForm;
  final Function(User) onToggleEditUserForm;
  final VoidCallback onCancelEdit;
  final Function({
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentor,
  }) onCreateUser;
  final Function({
    required String userId,
    required String name,
    required String email,
    required String userType,
    String? studentId,
    String? department,
    String? yearMajor,
    required String acknowledgmentSigned,
    String? mentorId,
  }) onUpdateUser;
  final Function(User) onDeleteUser;
  final Function({Function()? onSuccess}) onShowAuthOverlay;
  final bool isAuthenticated;
  final AuthService authService;

  const UserManagementSectionV2({
    super.key,
    required this.usersList,
    required this.loadingUsers,
    required this.onToggleAddUserForm,
    required this.onToggleEditUserForm,
    required this.onCancelEdit,
    required this.onCreateUser,
    required this.onUpdateUser,
    required this.onDeleteUser,
    required this.onShowAuthOverlay,
    required this.isAuthenticated,
    required this.authService,
  });

  @override
  State<UserManagementSectionV2> createState() => _UserManagementSectionV2State();
}

class _UserManagementSectionV2State extends State<UserManagementSectionV2> {
  String _searchQuery = '';
  String _selectedTypeFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<User> get _filteredUsers {
    var filtered = widget.usersList;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               (user.studentId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply type filter
    if (_selectedTypeFilter != 'all') {
      filtered = filtered.where((user) => user.userType == _selectedTypeFilter).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWrapper(
      title: 'User Management',
      icon: Icons.person_add,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with search and add button
              _buildHeader(context),
              const SizedBox(height: 16),
              
              // Filters
              _buildFilters(),
              const SizedBox(height: 16),
              
              // Users list with improved layout
              _buildUsersList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Authorized Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F2D52),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D52),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            labelText: 'Search users...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        const Text('Filter by type: '),
        const SizedBox(width: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'mentee', label: Text('Mentees')),
            ButtonSegment(value: 'mentor', label: Text('Mentors')),
            ButtonSegment(value: 'coordinator', label: Text('Coordinators')),
          ],
          selected: {_selectedTypeFilter},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedTypeFilter = newSelection.first;
            });
          },
        ),
        const Spacer(),
        Text(
          '${_filteredUsers.length} users',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    if (widget.loadingUsers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No users found matching "$_searchQuery"'
                  : 'No users found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: _filteredUsers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            return _buildUserListItem(context, user);
          },
        ),
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, User user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _getUserTypeColor(user.userType),
        child: Text(
          user.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getUserTypeColor(user.userType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.userType,
              style: TextStyle(
                fontSize: 12,
                color: _getUserTypeColor(user.userType),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (user.studentId != null && user.studentId!.isNotEmpty)
            Text('ID: ${user.studentId}', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditUserDialog(context, user),
            tooltip: 'Edit user',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => widget.onDeleteUser(user),
            tooltip: 'Delete user',
          ),
        ],
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'mentee':
        return Colors.blue;
      case 'mentor':
        return Colors.green;
      case 'coordinator':
        return Colors.orange;
      case 'developer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UserFormDialog(
        title: 'Add New User',
        user: null,
        mentors: widget.usersList.where((u) => u.userType == 'mentor').toList(),
        onSave: (data) async {
          try {
            await widget.onCreateUser(
              name: data['name']!,
              email: data['email']!,
              userType: data['userType']!,
              studentId: data['studentId'],
              department: data['department'],
              yearMajor: data['yearMajor'],
              acknowledgmentSigned: data['acknowledgmentSigned']!,
              mentor: data['mentorId'],
            );
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating user: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UserFormDialog(
        title: 'Edit User',
        user: user,
        mentors: widget.usersList.where((u) => u.userType == 'mentor').toList(),
        onSave: (data) async {
          try {
            await widget.onUpdateUser(
              userId: user.id,
              name: data['name']!,
              email: data['email']!,
              userType: data['userType']!,
              studentId: data['studentId'],
              department: data['department'],
              yearMajor: data['yearMajor'],
              acknowledgmentSigned: data['acknowledgmentSigned']!,
              mentorId: data['mentorId'],
            );
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating user: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

// Dialog widget for add/edit forms
class _UserFormDialog extends StatefulWidget {
  final String title;
  final User? user;
  final List<User> mentors;
  final Function(Map<String, String?>) onSave;

  const _UserFormDialog({
    required this.title,
    required this.user,
    required this.mentors,
    required this.onSave,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _departmentController;
  late final TextEditingController _yearMajorController;
  late String _selectedUserType;
  late String _selectedAcknowledgment;
  String? _selectedMentorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _studentIdController = TextEditingController(text: widget.user?.studentId ?? '');
    _departmentController = TextEditingController(text: widget.user?.department ?? '');
    _yearMajorController = TextEditingController(text: widget.user?.yearMajor ?? '');
    _selectedUserType = widget.user?.userType ?? 'mentee';
    _selectedAcknowledgment = widget.user?.acknowledgmentSigned ?? 'not_applicable';
    _selectedMentorId = widget.user?.mentor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _yearMajorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.user == null ? Icons.person_add : Icons.edit,
            color: SettingsConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Container(
        width: isMobile ? double.maxFinite : 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information
                _buildSectionHeader('Basic Information'),
                const SizedBox(height: 16),
                
                // Name and Email fields
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                // User Type
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    labelText: 'User Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                    DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                    DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value!;
                      if (value != 'mentee') {
                        _selectedMentorId = null;
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Additional Information
                _buildSectionHeader('Additional Information'),
                const SizedBox(height: 16),
                
                // Student ID and Department
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _departmentController,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextFormField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                // Year/Major
                TextFormField(
                  controller: _yearMajorController,
                  decoration: const InputDecoration(
                    labelText: 'Year/Major',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Acknowledgment
                DropdownButtonFormField<String>(
                  value: _selectedAcknowledgment,
                  decoration: const InputDecoration(
                    labelText: 'Acknowledgment Status *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'signed', child: Text('Signed')),
                    DropdownMenuItem(value: 'not_signed', child: Text('Not Signed')),
                    DropdownMenuItem(value: 'not_applicable', child: Text('Not Applicable')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAcknowledgment = value!;
                    });
                  },
                ),
                
                // Mentor selection for mentees
                if (_selectedUserType == 'mentee') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedMentorId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Mentor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.supervisor_account),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No Mentor Assigned'),
                      ),
                      ...widget.mentors.map((mentor) => DropdownMenuItem(
                        value: mentor.id,
                        child: Text(mentor.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMentorId = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.user == null ? 'Create User' : 'Update User'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: SettingsConstants.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2D52),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      widget.onSave({
        'name': _nameController.text,
        'email': _emailController.text,
        'userType': _selectedUserType,
        'studentId': _studentIdController.text.isEmpty ? null : _studentIdController.text,
        'department': _departmentController.text.isEmpty ? null : _departmentController.text,
        'yearMajor': _yearMajorController.text.isEmpty ? null : _yearMajorController.text,
        'acknowledgmentSigned': _selectedAcknowledgment,
        'mentorId': _selectedMentorId,
      });
    }
  }
}