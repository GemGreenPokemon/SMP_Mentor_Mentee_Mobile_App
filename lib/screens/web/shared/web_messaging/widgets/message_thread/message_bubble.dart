import 'package:flutter/material.dart';
import '../../../../../../models/message.dart';
import '../../models/message_status.dart';
import '../../utils/messaging_constants.dart';
import '../../utils/messaging_helpers.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String recipientName;
  final MessageStatus? messageStatus;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.recipientName,
    this.messageStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: showAvatar ? 8 : 4,
        left: isMe ? 64 : 0,
        right: isMe ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: MessagingConstants.messageAvatarSize / 2,
              backgroundColor: MessagingHelpers.getAvatarColor(recipientName),
              child: Text(
                MessagingHelpers.getInitials(recipientName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: MessagingConstants.messageAvatarSize + 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MessagingConstants.maxMessageWidth,
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe 
                          ? MessagingConstants.sentMessageColor 
                          : MessagingConstants.receivedMessageColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? MessagingConstants.messageBorderRadius : 4),
                        topRight: Radius.circular(isMe ? 4 : MessagingConstants.messageBorderRadius),
                        bottomLeft: const Radius.circular(MessagingConstants.messageBorderRadius),
                        bottomRight: const Radius.circular(MessagingConstants.messageBorderRadius),
                      ),
                      boxShadow: MessagingConstants.messageShadow,
                    ),
                    child: SelectableText(
                      message.message,
                      style: MessagingConstants.messageTextStyle.copyWith(
                        color: isMe 
                            ? MessagingConstants.sentMessageTextColor 
                            : MessagingConstants.receivedMessageTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MessagingHelpers.formatMessageTime(message.sentAt),
                        style: MessagingConstants.timestampStyle,
                      ),
                      if (isMe && messageStatus != null) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (messageStatus!.status) {
      case MessageStatusType.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatusType.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.grey,
        );
      case MessageStatusType.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey,
        );
      case MessageStatusType.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: MessagingConstants.primaryColor,
        );
      case MessageStatusType.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
    }
  }
}