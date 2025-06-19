import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}