import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../utils/chat_constants.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  
  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: ChatConstants.verticalSpacing),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * ChatConstants.messageMaxWidthRatio,
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatConstants.defaultPadding,
                vertical: ChatConstants.messagePadding,
              ),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? ChatConstants.myMessageColor 
                    : ChatConstants.otherMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(ChatConstants.messageBorderRadius),
                  topRight: const Radius.circular(ChatConstants.messageBorderRadius),
                  bottomLeft: Radius.circular(
                    message.isMe ? ChatConstants.messageBorderRadius : ChatConstants.messageSmallRadius
                  ),
                  bottomRight: Radius.circular(
                    message.isMe ? ChatConstants.messageSmallRadius : ChatConstants.messageBorderRadius
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.isMe ? Colors.white : Colors.black87,
                  fontSize: ChatConstants.messageFontSize,
                ),
              ),
            ),
            const SizedBox(height: ChatConstants.smallSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChatConstants.smallSpacing),
              child: Text(
                message.time,
                style: TextStyle(
                  fontSize: ChatConstants.timeFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}