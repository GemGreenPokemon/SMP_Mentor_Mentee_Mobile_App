import 'package:flutter/material.dart';
import '../../models/checklist.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final Checklist checklist;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.checklist,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Checklist'),
      content: Text(
        'Are you sure you want to delete "${checklist.title}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}