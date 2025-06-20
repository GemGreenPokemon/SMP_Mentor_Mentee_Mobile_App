import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'utils/chat_constants.dart';
import 'utils/chat_helpers.dart';
import 'widgets/conversation_sidebar.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/message_input_area.dart';
import 'widgets/dialogs/clear_chat_dialog.dart';
import 'widgets/dialogs/block_user_dialog.dart';

class WebChatScreen extends StatefulWidget {
  final String recipientName;
  final String recipientRole;

  const WebChatScreen({
    super.key,
    required this.recipientName,
    required this.recipientRole,
  });

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mock data
  late List<ChatMessage> messages;
  late List<Conversation> conversations;

  @override
  void initState() {
    super.initState();
    messages = ChatHelpers.createMockMessages();
    conversations = ChatHelpers.createMockConversations(
      widget.recipientName,
      widget.recipientRole,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (!ChatHelpers.canSendMessage(_messageController.text)) return;

    setState(() {
      messages.add(ChatMessage(
        id: 'msg_${messages.length}',
        sender: 'You',
        message: _messageController.text.trim(),
        time: ChatHelpers.formatCurrentTime(context),
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    ChatHelpers.scrollToBottom(_scrollController);
  }

  void _showClearChatDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ClearChatDialog(),
    );

    if (result == true && mounted) {
      setState(() {
        messages.clear();
      });
      ChatHelpers.showSnackBar(context, ChatConstants.chatClearedMessage);
    }
  }

  void _showBlockUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BlockUserDialog(userName: widget.recipientName),
    );

    if (result == true && mounted) {
      Navigator.pop(context); // Return to previous screen
      ChatHelpers.showSnackBar(
        context,
        ChatHelpers.formatUserBlockedMessage(widget.recipientName),
      );
    }
  }

  void _onConversationTap(Conversation conversation) {
    // Switch conversation logic would go here
    // For now, just update the active state
    setState(() {
      for (var conv in conversations) {
        conv = conv.copyWith(isActive: false);
      }
      conversation = conversation.copyWith(isActive: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Conversation list sidebar (desktop/tablet only)
          if (isDesktop || isTablet)
            ConversationSidebar(
              conversations: conversations,
              onConversationTap: _onConversationTap,
            ),
          
          // Main chat area
          Expanded(
            child: Column(
              children: [
                // Chat header
                ChatHeader(
                  recipientName: widget.recipientName,
                  recipientRole: widget.recipientRole,
                  showBackButton: !isDesktop && !isTablet,
                  onClearChat: _showClearChatDialog,
                  onBlockUser: _showBlockUserDialog,
                ),
                
                // Messages area
                Expanded(
                  child: Container(
                    color: ChatConstants.messagesBackgroundColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(ChatConstants.defaultPadding),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageBubble(
                          message: messages[index],
                        );
                      },
                    ),
                  ),
                ),
                
                // Message input area
                MessageInputArea(
                  messageController: _messageController,
                  onSendMessage: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}