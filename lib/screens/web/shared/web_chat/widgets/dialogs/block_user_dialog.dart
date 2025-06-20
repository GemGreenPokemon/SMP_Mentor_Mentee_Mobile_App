import 'package:flutter/material.dart';
import '../../utils/chat_constants.dart';
import '../../utils/chat_helpers.dart';

class BlockUserDialog extends StatelessWidget {
  final String userName;
  
  const BlockUserDialog({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ChatConstants.blockUserTitle),
      content: Text(ChatHelpers.formatBlockUserMessage(userName)),
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
          child: const Text(ChatConstants.blockAction),
        ),
      ],
    );
  }
}