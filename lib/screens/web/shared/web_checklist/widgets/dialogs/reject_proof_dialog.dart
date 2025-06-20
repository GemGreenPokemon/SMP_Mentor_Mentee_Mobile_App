import 'package:flutter/material.dart';

class RejectProofDialog extends StatefulWidget {
  final Function(String feedback) onReject;

  const RejectProofDialog({
    super.key,
    required this.onReject,
  });

  @override
  State<RejectProofDialog> createState() => _RejectProofDialogState();
}

class _RejectProofDialogState extends State<RejectProofDialog> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Proof'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide feedback for the mentee:'),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              labelText: 'Feedback',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onReject(_feedbackController.text);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}