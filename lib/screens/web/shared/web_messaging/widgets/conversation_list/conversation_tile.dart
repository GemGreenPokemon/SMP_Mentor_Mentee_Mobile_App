import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../utils/messaging_constants.dart';
import '../../utils/messaging_helpers.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MessagingConstants.animationDuration,
      curve: MessagingConstants.animationCurve,
      margin: const EdgeInsets.symmetric(
        horizontal: MessagingConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected ? MessagingConstants.primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.userName,
                              style: MessagingConstants.conversationTitleStyle.copyWith(
                                fontWeight: conversation.unreadCount > 0 
                                    ? FontWeight.bold 
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            MessagingHelpers.formatTimestamp(
                              conversation.lastMessageTime,
                              context,
                            ),
                            style: MessagingConstants.timestampStyle.copyWith(
                              color: conversation.unreadCount > 0
                                  ? MessagingConstants.primaryColor
                                  : null,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage.isEmpty 
                                  ? 'Start a conversation' 
                                  : conversation.lastMessage,
                              style: MessagingConstants.conversationSubtitleStyle.copyWith(
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w500
                                    : null,
                                color: conversation.unreadCount > 0
                                    ? Colors.black87
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: MessagingConstants.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99 
                                    ? '99+' 
                                    : conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: MessagingConstants.conversationAvatarSize / 2,
          backgroundColor: MessagingHelpers.getAvatarColor(conversation.userName),
          backgroundImage: conversation.avatarUrl != null
              ? NetworkImage(conversation.avatarUrl!)
              : null,
          child: conversation.avatarUrl == null
              ? Text(
                  MessagingHelpers.getInitials(conversation.userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (conversation.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: MessagingConstants.onlineStatusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}