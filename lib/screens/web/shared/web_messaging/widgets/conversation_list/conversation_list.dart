import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/conversation_controller.dart';
import '../../utils/messaging_constants.dart';
import 'conversation_tile.dart';
import 'conversation_search.dart';

class ConversationList extends StatelessWidget {
  final Function(String conversationId, String userId, String userName, String userRole) onConversationSelected;
  final String? selectedConversationId;

  const ConversationList({
    super.key,
    required this.onConversationSelected,
    this.selectedConversationId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            _buildHeader(context),
            ConversationSearch(
              onSearchChanged: controller.updateSearchQuery,
              searchQuery: controller.searchQuery,
            ),
            Expanded(
              child: _buildConversationList(controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MessagingConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chat,
            color: MessagingConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ConversationController>().refresh();
            },
            tooltip: 'Refresh conversations',
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(ConversationController controller) {
    if (controller.isLoading && !controller.hasConversations) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MessagingConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load conversations',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final conversations = controller.conversations;

    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MessagingConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.isEmpty
                    ? MessagingConstants.emptyConversationsMessage
                    : 'No conversations found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (controller.searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ConversationTile(
            conversation: conversation,
            isSelected: selectedConversationId == conversation.id,
            onTap: () => onConversationSelected(
              conversation.id,
              conversation.userId,
              conversation.userName,
              conversation.userRole,
            ),
          );
        },
      ),
    );
  }
}