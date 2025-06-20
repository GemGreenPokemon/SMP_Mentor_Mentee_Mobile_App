import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../utils/chat_constants.dart';
import 'conversation_list_item.dart';

class ConversationSidebar extends StatelessWidget {
  final List<Conversation> conversations;
  final Function(Conversation) onConversationTap;
  
  const ConversationSidebar({
    super.key,
    required this.conversations,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SizedBox(
        width: ChatConstants.sidebarWidth,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(ChatConstants.defaultPadding),
              child: TextField(
                decoration: InputDecoration(
                  hintText: ChatConstants.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChatConstants.defaultPadding,
                    vertical: ChatConstants.messagePadding,
                  ),
                ),
              ),
            ),
            // Conversation list
            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ConversationListItem(
                    conversation: conversation,
                    onTap: () => onConversationTap(conversation),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}