import 'package:flutter/material.dart';
import 'dart:ui';

class DeleteConfirmationDialog extends StatelessWidget {
  final String announcementTitle;
  final VoidCallback onDeletePressed;

  const DeleteConfirmationDialog({
    super.key,
    required this.announcementTitle,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "$announcementTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDeletePressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}