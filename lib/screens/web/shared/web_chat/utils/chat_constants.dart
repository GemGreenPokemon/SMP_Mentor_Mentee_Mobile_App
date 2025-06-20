import 'package:flutter/material.dart';

class ChatConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color backgroundColor = Colors.white;
  static const Color messagesBackgroundColor = Color(0xFFF5F5F5);
  static const Color myMessageColor = primaryColor;
  static const Color otherMessageColor = Colors.white;
  static const Color activeConversationColor = Color(0xFFE0E0E0);
  
  // Sizes
  static const double sidebarWidth = 300.0;
  static const double avatarRadius = 20.0;
  static const double messageMaxWidthRatio = 0.6;
  static const double messageBorderRadius = 16.0;
  static const double messageSmallRadius = 4.0;
  static const double iconSize = 24.0;
  
  // Padding and Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double messagePadding = 12.0;
  static const double verticalSpacing = 12.0;
  static const double smallSpacing = 4.0;
  
  // Text Sizes
  static const double titleFontSize = 16.0;
  static const double subtitleFontSize = 14.0;
  static const double messageFontSize = 14.0;
  static const double timeFontSize = 12.0;
  static const double badgeFontSize = 10.0;
  
  // Animation Durations
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration messageAnimationDelay = Duration(milliseconds: 100);
  
  // Text Content
  static const String searchHint = 'Search conversations...';
  static const String messageHint = 'Type a message...';
  static const String attachFileTooltip = 'Attach file';
  static const String sendTooltip = 'Send message';
  static const String videoCallTooltip = 'Start video call';
  static const String voiceCallTooltip = 'Start voice call';
  
  // Feature Messages
  static const String videoCallComingSoon = 'Video call feature coming soon!';
  static const String voiceCallComingSoon = 'Voice call feature coming soon!';
  static const String fileAttachmentComingSoon = 'File attachment coming soon!';
  
  // Dialog Messages
  static const String clearChatTitle = 'Clear Chat';
  static const String clearChatMessage = 'Are you sure you want to clear this chat? This action cannot be undone.';
  static const String blockUserTitle = 'Block User';
  static const String blockUserMessagePrefix = 'Are you sure you want to block ';
  static const String blockUserMessageSuffix = '? You will no longer receive messages from this user.';
  static const String chatClearedMessage = 'Chat cleared';
  static const String userBlockedSuffix = ' has been blocked';
  
  // Action Labels
  static const String cancelAction = 'Cancel';
  static const String clearAction = 'Clear';
  static const String blockAction = 'Block';
  
  // Menu Items
  static const String clearChatMenuItem = 'Clear chat';
  static const String blockUserMenuItem = 'Block user';
  
  // Mock Data
  static const List<Map<String, dynamic>> mockMessages = [
    {
      'sender': 'You',
      'message': 'Hi! I wanted to discuss my progress on the current assignment.',
      'time': '10:30 AM',
      'isMe': true,
    },
    {
      'sender': 'Sarah Martinez',
      'message': 'Hello! I\'d be happy to discuss that. How are things going?',
      'time': '10:32 AM',
      'isMe': false,
    },
    {
      'sender': 'You',
      'message': 'I\'m making good progress but have a few questions about the requirements.',
      'time': '10:33 AM',
      'isMe': true,
    },
    {
      'sender': 'Sarah Martinez',
      'message': 'Sure, what questions do you have? I\'m here to help!',
      'time': '10:35 AM',
      'isMe': false,
    },
  ];
}