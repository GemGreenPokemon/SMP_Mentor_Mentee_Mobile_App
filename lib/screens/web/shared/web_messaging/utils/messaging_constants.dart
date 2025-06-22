import 'package:flutter/material.dart';

class MessagingConstants {
  // Layout
  static const double sidebarWidth = 350.0;
  static const double minMessageWidth = 300.0;
  static const double maxMessageWidth = 500.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color messagesBackgroundColor = Color(0xFFF8F9FA);
  static const Color sidebarBackgroundColor = Colors.white;
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color sentMessageColor = Color(0xFF1976D2);
  static const Color receivedMessageColor = Colors.white;
  static const Color sentMessageTextColor = Colors.white;
  static const Color receivedMessageTextColor = Color(0xFF212121);
  static const Color typingIndicatorColor = Color(0xFF757575);
  static const Color onlineStatusColor = Color(0xFF4CAF50);
  static const Color offlineStatusColor = Color(0xFF757575);
  
  // Text Styles
  static const TextStyle conversationTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF212121),
  );
  
  static const TextStyle conversationSubtitleStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF757575),
  );
  
  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 14,
    height: 1.4,
  );
  
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF9E9E9E),
  );
  
  // Animations
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration typingIndicatorDelay = Duration(seconds: 3);
  static const Curve animationCurve = Curves.easeOutCubic;
  
  // Message limits
  static const int maxMessageLength = 1000;
  static const int initialMessageLoadCount = 50;
  static const int messageLoadMoreCount = 25;
  
  // Typing indicator
  static const Duration typingTimeout = Duration(seconds: 5);
  static const Duration typingDebounce = Duration(seconds: 1);
  
  // Shadows and elevations
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> messageShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ];
  
  // Border radius
  static const double defaultBorderRadius = 12.0;
  static const double messageBorderRadius = 16.0;
  static const double inputBorderRadius = 24.0;
  
  // Avatar sizes
  static const double conversationAvatarSize = 48.0;
  static const double messageAvatarSize = 32.0;
  
  // Input field
  static const double inputFieldHeight = 48.0;
  static const double inputFieldMaxHeight = 120.0;
  
  // Error messages
  static const String connectionErrorMessage = 'Unable to connect. Please check your internet connection.';
  static const String sendErrorMessage = 'Failed to send message. Please try again.';
  static const String loadErrorMessage = 'Failed to load messages. Please try again.';
  static const String emptyConversationsMessage = 'No conversations yet';
  static const String emptyMessagesMessage = 'No messages yet. Start the conversation!';
}