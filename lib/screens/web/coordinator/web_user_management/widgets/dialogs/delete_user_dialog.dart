import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/models/user.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import '../../utils/user_management_constants.dart';
import '../../utils/user_management_helpers.dart';

class DeleteUserDialog extends StatefulWidget {
  final User user;

  const DeleteUserDialog({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final _cloudFunctionService = CloudFunctionService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get university path
      final universityPath = _cloudFunctionService.getCurrentUniversityPath();
      
      await _cloudFunctionService.deleteUserAccount(
        universityPath: universityPath,
        userId: widget.user.id,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${widget.user.name} deleted successfully'),
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
            Icons.warning_amber_rounded,
            color: UserManagementConstants.errorColor,
          ),
          const SizedBox(width: 8),
          const Text('Delete User'),
        ],
      ),
      content: Container(
        width: 400,
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
            
            Text(
              UserManagementConstants.deleteConfirmationMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: UserManagementConstants.spacing),
            
            // User Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: UserManagementHelpers.getUserTypeColor(widget.user.userType).withOpacity(0.2),
                        child: Text(
                          widget.user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: UserManagementHelpers.getUserTypeColor(widget.user.userType),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(widget.user.userType),
                        backgroundColor: UserManagementHelpers.getUserTypeColor(widget.user.userType).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: UserManagementHelpers.getUserTypeColor(widget.user.userType),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.user.studentId != null)
                        Chip(
                          label: Text('ID: ${widget.user.studentId}'),
                          backgroundColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      if (widget.user.department != null)
                        Chip(
                          label: Text(widget.user.department!),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UserManagementConstants.spacing),
            
            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UserManagementConstants.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: UserManagementConstants.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning,
                    color: UserManagementConstants.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: UserManagementConstants.warningColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All user data, including meetings, messages, and other associated data will be permanently deleted.',
                          style: TextStyle(
                            fontSize: 12,
                            color: UserManagementConstants.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(UserManagementConstants.cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: UserManagementConstants.errorColor,
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
              : const Text(UserManagementConstants.deleteButtonLabel),
        ),
      ],
    );
  }
}