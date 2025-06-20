import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../utils/chat_constants.dart';

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  
  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: conversation.isActive,
      selectedTileColor: ChatConstants.activeConversationColor,
      leading: CircleAvatar(
        backgroundColor: ChatConstants.primaryColor,
        radius: ChatConstants.avatarRadius,
        child: Text(
          conversation.initials,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        conversation.name,
        style: TextStyle(
          fontWeight: conversation.hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.hasUnread ? Colors.black87 : Colors.grey[600],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.lastMessageTime,
            style: TextStyle(
              fontSize: ChatConstants.timeFontSize,
              color: conversation.hasUnread ? ChatConstants.primaryColor : Colors.grey[600],
            ),
          ),
          if (conversation.hasUnread)
            Container(
              margin: const EdgeInsets.only(top: ChatConstants.smallSpacing),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: ChatConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: ChatConstants.badgeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}