import 'package:flutter/material.dart';
import '../utils/chat_constants.dart';
import '../utils/chat_helpers.dart';

class MessageInputArea extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  
  const MessageInputArea({
    super.key,
    required this.messageController,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChatConstants.defaultPadding),
      decoration: BoxDecoration(
        color: ChatConstants.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              ChatHelpers.showSnackBar(context, ChatConstants.fileAttachmentComingSoon);
            },
            tooltip: ChatConstants.attachFileTooltip,
          ),
          const SizedBox(width: ChatConstants.smallPadding),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: ChatConstants.messageHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ChatConstants.defaultPadding,
                  vertical: ChatConstants.messagePadding,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => onSendMessage(),
            ),
          ),
          const SizedBox(width: ChatConstants.smallPadding),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSendMessage,
            color: ChatConstants.primaryColor,
            tooltip: ChatConstants.sendTooltip,
          ),
        ],
      ),
    );
  }
}