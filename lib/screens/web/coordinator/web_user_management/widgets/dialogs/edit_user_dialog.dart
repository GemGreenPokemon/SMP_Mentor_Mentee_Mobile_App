import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import '../../utils/user_management_constants.dart';
import '../../utils/user_management_helpers.dart';

class EditUserDialog extends StatefulWidget {
  final User user;

  const EditUserDialog({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cloudFunctionService = CloudFunctionService();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;
  
  late String _selectedUserType;
  late bool _hasAcknowledged;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _studentIdController = TextEditingController(text: widget.user.studentId ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
    _yearController = TextEditingController(text: widget.user.yearMajor ?? '');
    _selectedUserType = widget.user.userType;
    _hasAcknowledged = widget.user.acknowledgmentSigned != 'not_applicable' && 
                       widget.user.acknowledgmentSigned != 'No';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get university path
      final universityPath = _cloudFunctionService.getCurrentUniversityPath();
      
      await _cloudFunctionService.updateUserAccount(
        universityPath: universityPath,
        userId: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        department: _departmentController.text.trim().isEmpty 
            ? null 
            : _departmentController.text.trim(),
        yearMajor: _yearController.text.trim().isEmpty 
            ? null 
            : _yearController.text.trim(),
        acknowledgmentSigned: _hasAcknowledged ? 'Yes' : 'No',
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${_nameController.text.trim()} updated successfully'),
            backgroundColor: UserManagementConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            UserManagementConstants.editIcon,
            color: UserManagementConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          const Text(UserManagementConstants.editUserTitle),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: UserManagementConstants.dialogWidth,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UserManagementConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: UserManagementConstants.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: UserManagementConstants.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: UserManagementConstants.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UserManagementConstants.spacing),
                ],
                
                // User ID (read-only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'User ID: ${widget.user.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // User Type Selection
                const Text(
                  'User Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'mentee',
                      label: Text('Mentee'),
                      icon: Icon(UserManagementConstants.menteeIcon),
                    ),
                    ButtonSegment(
                      value: 'mentor',
                      label: Text('Mentor'),
                      icon: Icon(UserManagementConstants.mentorIcon),
                    ),
                    ButtonSegment(
                      value: 'coordinator',
                      label: Text('Coordinator'),
                      icon: Icon(UserManagementConstants.coordinatorIcon),
                    ),
                  ],
                  selected: {_selectedUserType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedUserType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter user\'s full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return UserManagementConstants.requiredFieldMessage;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'user@ucmerced.edu',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return UserManagementConstants.requiredFieldMessage;
                    }
                    if (!UserManagementHelpers.isValidEmail(value.trim())) {
                      return UserManagementConstants.invalidEmailMessage;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // Student ID Field (optional)
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'Optional student ID',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // Department Field (optional)
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    hintText: 'e.g., Computer Science',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: UserManagementConstants.spacing),
                
                // Year/Major Field (optional, for mentees)
                if (_selectedUserType == 'mentee') ...[
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      hintText: 'e.g., 1, 2, 3, 4',
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1 || year > 4) {
                          return UserManagementConstants.invalidYearMessage;
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: UserManagementConstants.spacing),
                ],
                
                // Acknowledgment Status
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    title: const Text('Has Acknowledged'),
                    subtitle: Text(
                      'User has completed the acknowledgment process',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: _hasAcknowledged,
                    onChanged: (value) {
                      setState(() {
                        _hasAcknowledged = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                
                // Mentor Assignment Info (for mentees)
                if (widget.user.userType == 'mentee' && widget.user.mentor != null && widget.user.mentor!.isNotEmpty) ...[
                  const SizedBox(height: UserManagementConstants.spacing),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This mentee has an assigned mentor. Use the mentor management features to modify mentor assignments.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(UserManagementConstants.cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: UserManagementConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(UserManagementConstants.saveButtonLabel),
        ),
      ],
    );
  }
}