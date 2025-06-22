import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/message_controller.dart';
import '../../utils/messaging_constants.dart';
import '../../utils/messaging_helpers.dart';
import 'message_bubble.dart';
import 'message_composer.dart';
import 'typing_indicator.dart';

class MessageThread extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String recipientRole;
  final VoidCallback? onBack;

  const MessageThread({
    super.key,
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientRole,
    this.onBack,
  });

  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more messages when near the end
      context.read<MessageController>().loadMoreMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                color: MessagingConstants.messagesBackgroundColor,
                child: _buildMessagesList(controller),
              ),
            ),
            if (controller.typingIndicator != null)
              TypingIndicatorWidget(
                typingIndicator: controller.typingIndicator!,
              ),
            MessageComposer(
              onSendMessage: (message) async {
                final success = await controller.sendMessage(message);
                if (success) {
                  _scrollToBottom();
                } else {
                  MessagingHelpers.showSnackBar(
                    context,
                    MessagingConstants.sendErrorMessage,
                    isError: true,
                  );
                }
                return success;
              },
              onTypingChanged: controller.updateTypingStatus,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              color: Colors.grey[700],
            ),
          CircleAvatar(
            radius: 20,
            backgroundColor: MessagingHelpers.getAvatarColor(widget.recipientName),
            child: Text(
              MessagingHelpers.getInitials(widget.recipientName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                Text(
                  widget.recipientRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog(context);
                  break;
                case 'info':
                  _showUserInfo(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('User Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 12),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(MessageController controller) {
    if (controller.isLoading && !controller.hasMessages) {
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
                MessagingConstants.loadErrorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  controller.loadMessages(
                    widget.conversationId,
                    controller.currentUserId,
                    widget.recipientId,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = controller.messages;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MessagingConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waving_hand,
                size: 64,
                color: Colors.orange[300],
              ),
              const SizedBox(height: 16),
              Text(
                MessagingConstants.emptyMessagesMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Say hello to ${widget.recipientName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: MessagingConstants.defaultPadding,
        vertical: MessagingConstants.smallPadding,
      ),
      itemCount: messages.length + (controller.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          // Loading indicator for more messages
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final message = messages[index];
        final previousMessage = index < messages.length - 1 ? messages[index + 1] : null;
        final nextMessage = index > 0 ? messages[index - 1] : null;
        
        final showDateSeparator = MessagingHelpers.shouldShowDateSeparator(
          message.sentAt,
          previousMessage?.sentAt,
        );
        
        return Column(
          children: [
            if (showDateSeparator)
              _buildDateSeparator(message.sentAt),
            MessageBubble(
              message: message,
              isMe: message.senderId == controller.currentUserId,
              showAvatar: nextMessage == null || 
                         nextMessage.senderId != message.senderId ||
                         MessagingHelpers.shouldShowDateSeparator(
                           nextMessage.sentAt,
                           message.sentAt,
                         ),
              recipientName: message.senderId != controller.currentUserId 
                  ? widget.recipientName 
                  : 'You',
              messageStatus: controller.getMessageStatus(message.id),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[300],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              MessagingHelpers.formatDateSeparator(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      MessagingHelpers.scrollToBottom(_scrollController);
    }
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear chat
              Navigator.pop(context);
              MessagingHelpers.showSnackBar(
                context,
                'Chat cleared successfully',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.recipientName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: MessagingHelpers.getAvatarColor(widget.recipientName),
              child: Text(
                MessagingHelpers.getInitials(widget.recipientName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Role: ${widget.recipientRole}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}