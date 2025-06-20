import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'chat_constants.dart';

class ChatHelpers {
  /// Shows a snackbar with the given message
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  /// Scrolls to the bottom of the chat
  static void scrollToBottom(ScrollController scrollController) {
    Future.delayed(ChatConstants.messageAnimationDelay, () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: ChatConstants.scrollAnimationDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// Formats the current time for display
  static String formatCurrentTime(BuildContext context) {
    return TimeOfDay.now().format(context);
  }
  
  /// Creates mock conversations for demonstration
  static List<Conversation> createMockConversations(String recipientName, String recipientRole) {
    return [
      Conversation(
        id: '1',
        name: recipientName,
        role: recipientRole,
        lastMessage: 'I\'m here to help!',
        lastMessageTime: '10:35 AM',
        isActive: true,
        hasUnread: true,
        unreadCount: 2,
        lastUpdated: DateTime.now(),
      ),
      Conversation(
        id: '2',
        name: 'Clarissa Correa',
        role: 'Program Coordinator',
        lastMessage: 'Please review the updated guidelines',
        lastMessageTime: 'Yesterday',
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Conversation(
        id: '3',
        name: 'John Davis',
        role: '4th Year, Biology Major',
        lastMessage: 'Thanks for the resources!',
        lastMessageTime: '2 days ago',
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
  
  /// Creates mock messages from the constants
  static List<ChatMessage> createMockMessages() {
    return ChatConstants.mockMessages.asMap().entries.map((entry) {
      final index = entry.key;
      final messageData = entry.value;
      
      return ChatMessage(
        id: 'msg_$index',
        sender: messageData['sender'],
        message: messageData['message'],
        time: messageData['time'],
        isMe: messageData['isMe'],
        timestamp: DateTime.now().subtract(Duration(minutes: 10 - index)),
      );
    }).toList();
  }
  
  /// Validates if a message can be sent
  static bool canSendMessage(String message) {
    return message.trim().isNotEmpty;
  }
  
  /// Formats the block user message
  static String formatBlockUserMessage(String userName) {
    return '${ChatConstants.blockUserMessagePrefix}$userName${ChatConstants.blockUserMessageSuffix}';
  }
  
  /// Formats the user blocked message
  static String formatUserBlockedMessage(String userName) {
    return '$userName${ChatConstants.userBlockedSuffix}';
  }
}