import 'package:flutter/material.dart';
import '../../models/resource.dart';
import '../../utils/resource_constants.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final Resource? resource;
  final bool isBulkDelete;
  final int deleteCount;

  const DeleteConfirmationDialog({
    super.key,
    this.resource,
    this.isBulkDelete = false,
    this.deleteCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isBulkDelete ? 'Delete Multiple Documents' : 'Delete Document'),
      content: Text(
        isBulkDelete
            ? 'Are you sure you want to delete $deleteCount documents? This action cannot be undone.'
            : 'Are you sure you want to delete "${resource?.title}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(isBulkDelete ? 'Delete All' : 'Delete'),
        ),
      ],
    );
  }
}