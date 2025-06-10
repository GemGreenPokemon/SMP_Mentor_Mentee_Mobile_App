import 'package:flutter/material.dart';
import '../widgets/settings_section_wrapper.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive.dart';

class UserManagementSection extends StatelessWidget {
  final List<User> usersList;
  final bool loadingUsers;
  final bool showAddUserForm;
  final bool showEditUserForm;
  final User? editingUser;
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

  const UserManagementSection({
    super.key,
    required this.usersList,
    required this.loadingUsers,
    required this.showAddUserForm,
    required this.showEditUserForm,
    required this.editingUser,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Authorized Users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onToggleAddUserForm,
                    icon: Icon(showAddUserForm ? Icons.close : Icons.person_add),
                    label: Text(showAddUserForm ? 'Cancel' : 'Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2D52),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Add user form
              if (showAddUserForm) ...[
                _buildAddUserForm(context),
                const SizedBox(height: 24),
              ],
              
              // Edit user form
              if (showEditUserForm && editingUser != null) ...[
                _buildEditUserForm(context),
                const SizedBox(height: 24),
              ],
              
              // Users list
              _buildUsersList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddUserForm(BuildContext context) {
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
                // Row 1: Name and Email - Make responsive
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
                
                // Row 2: Student ID and User Type - Make responsive
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
                
                // Row 3: Department and Year/Major - Make responsive
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
                        ...usersList
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
                    onToggleAddUserForm();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    // Validate required fields
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
                      await onCreateUser(
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

                      // Clear form and hide it
                      nameController.clear();
                      emailController.clear();
                      studentIdController.clear();
                      departmentController.clear();
                      yearMajorController.clear();

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

  Widget _buildEditUserForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setFormState) {
        // Form controllers with pre-populated data
        final nameController = TextEditingController(text: editingUser?.name ?? '');
        final emailController = TextEditingController(text: editingUser?.email ?? '');
        final studentIdController = TextEditingController(text: editingUser?.studentId ?? '');
        final departmentController = TextEditingController(text: editingUser?.department ?? '');
        final yearMajorController = TextEditingController(text: editingUser?.yearMajor ?? '');
        
        String selectedUserType = editingUser?.userType ?? 'mentee';
        String selectedAcknowledgment = editingUser?.acknowledgmentSigned ?? 'not_applicable';
        String? selectedMentor = editingUser?.mentor;
        bool isSubmitting = false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Edit User: ${editingUser?.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 1: Name and Email
              Responsive.isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
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
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                          ),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUserType,
                            decoration: const InputDecoration(
                              labelText: 'User Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                              DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                              DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                            ],
                            onChanged: (value) {
                              setFormState(() {
                                selectedUserType = value!;
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedUserType,
                          decoration: const InputDecoration(
                            labelText: 'User Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mentee', child: Text('Mentee')),
                            DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                            DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
                          ],
                          onChanged: (value) {
                            setFormState(() {
                              selectedUserType = value!;
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: yearMajorController,
                            decoration: const InputDecoration(
                              labelText: 'Year/Major',
                              border: OutlineInputBorder(),
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: yearMajorController,
                          decoration: const InputDecoration(
                            labelText: 'Year/Major',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),

              // Mentee-specific fields
              if (selectedUserType == 'mentee') ...[
                const SizedBox(height: 16),
                
                // Acknowledgment Status
                DropdownButtonFormField<String>(
                  value: selectedAcknowledgment,
                  decoration: const InputDecoration(
                    labelText: 'Acknowledgment Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'not_applicable', child: Text('Not Applicable')),
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'no', child: Text('No')),
                  ],
                  onChanged: (value) {
                    setFormState(() {
                      selectedAcknowledgment = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Mentor Assignment
                DropdownButtonFormField<String?>(
                  value: selectedMentor,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Mentor',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Mentor Assigned')),
                    ...usersList
                        .where((user) => user.userType == 'mentor')
                        .map((mentor) => DropdownMenuItem(
                              value: mentor.id,
                              child: Text(mentor.name),
                            )),
                  ],
                  onChanged: (value) {
                    setFormState(() {
                      selectedMentor = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSubmitting ? null : onCancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      // Validate and update user
                      if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
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
                        await onUpdateUser(
                          userId: editingUser!.id,
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          userType: selectedUserType,
                          studentId: studentIdController.text.trim().isEmpty ? null : studentIdController.text.trim(),
                          department: departmentController.text.trim().isEmpty ? null : departmentController.text.trim(),
                          yearMajor: yearMajorController.text.trim().isEmpty ? null : yearMajorController.text.trim(),
                          acknowledgmentSigned: selectedAcknowledgment,
                          mentorId: selectedMentor,
                        );

                        onCancelEdit();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setFormState(() => isSubmitting = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating user: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update User'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersList() {
    if (loadingUsers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (usersList.isEmpty) {
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
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 16),
                const Expanded(flex: 2, child: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 12),
                const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          ),
          
          // User rows
          ...(usersList.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            
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
                          onPressed: () => onToggleEditUserForm(user),
                          tooltip: 'Edit User',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () => onDeleteUser(user),
                          tooltip: 'Delete User',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

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
    // TODO: Implement logic to check if user has Firebase Auth account
    return Colors.orange; // For now, assume all are pending
  }

  String _getStatusText(User user) {
    // TODO: Implement logic to check if user has Firebase Auth account
    return 'Pending'; // For now, assume all are pending
  }
}