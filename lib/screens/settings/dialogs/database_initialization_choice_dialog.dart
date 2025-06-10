import 'package:flutter/material.dart';

class DatabaseInitializationChoiceDialog extends StatelessWidget {
  const DatabaseInitializationChoiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Color(0xFF0F2D52)),
          SizedBox(width: 8),
          Text('Initialize Database'),
        ],
      ),
      content: const Text(
        'Choose initialization method:\n\n'
        '• Cloud Function: Secure, authenticated\n'
        '• Direct: Development testing only',
      ),
      actions: [
        TextButton(
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context, 'cancel');
            });
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context, 'direct');
            });
          },
          child: const Text('Direct (Test)'),
        ),
        ElevatedButton(
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context, 'cloud');
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2D52),
            foregroundColor: Colors.white,
          ),
          child: const Text('Cloud Function'),
        ),
      ],
    );
  }
}