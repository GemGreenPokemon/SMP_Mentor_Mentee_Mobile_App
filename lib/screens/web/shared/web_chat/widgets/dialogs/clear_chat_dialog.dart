import 'package:flutter/material.dart';
import '../../utils/chat_constants.dart';

class ClearChatDialog extends StatelessWidget {
  const ClearChatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ChatConstants.clearChatTitle),
      content: const Text(ChatConstants.clearChatMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(ChatConstants.cancelAction),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text(ChatConstants.clearAction),
        ),
      ],
    );
  }
}