import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/messaging_service.dart';
import '../models/typing_indicator.dart';
import '../models/message_status.dart';
import '../../../../../models/message.dart';
import '../utils/messaging_constants.dart';

class MessageController extends ChangeNotifier {
  final MessagingService messagingService;
  final String currentUserId;
  
  // State
  String? _currentConversationId;
  String? _currentRecipientId;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _messageLimit = MessagingConstants.initialMessageLoadCount;
  
  // Subscriptions
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<TypingIndicator?>? _typingSubscription;
  
  // Typing indicator
  TypingIndicator? _typingIndicator;
  Timer? _typingTimer;
  bool _isTyping = false;
  
  // Message status tracking
  final Map<String, MessageStatus> _messageStatuses = {};
  
  MessageController({
    required this.messagingService,
    required this.currentUserId,
  });
  
  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  TypingIndicator? get typingIndicator => _typingIndicator;
  bool get hasMessages => _messages.isNotEmpty;
  String? get currentConversationId => _currentConversationId;
  
  /// Load messages for a conversation
  void loadMessages(String conversationId, String currentUserId, String recipientId) {
    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      return; // Already loaded
    }
    
    _currentConversationId = conversationId;
    _currentRecipientId = recipientId;
    _messages = [];
    _messageLimit = MessagingConstants.initialMessageLoadCount;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Cancel existing subscriptions
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    
    // Subscribe to messages
    _messagesSubscription = messagingService
        .getMessagesStream(conversationId, _messageLimit)
        .listen(
      (messages) {
        _messages = messages;
        _hasMore = messages.length >= _messageLimit;
        _isLoading = false;
        _error = null;
        notifyListeners();
        
        // Mark messages as read
        messagingService.markMessagesAsRead(conversationId, currentUserId);
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    
    // Subscribe to typing indicators
    _typingSubscription = messagingService
        .getTypingIndicatorStream(conversationId, currentUserId)
        .listen(
      (indicator) {
        _typingIndicator = indicator;
        notifyListeners();
      },
    );
  }
  
  /// Load more messages
  Future<void> loadMoreMessages() async {
    if (!_hasMore || _isLoading || _currentConversationId == null) return;
    
    _messageLimit += MessagingConstants.messageLoadMoreCount;
    loadMessages(_currentConversationId!, currentUserId, _currentRecipientId!);
  }
  
  /// Send a message
  Future<bool> sendMessage(String message) async {
    if (_currentConversationId == null || message.trim().isEmpty) {
      return false;
    }
    
    // Create temporary message ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add message to list immediately (optimistic update)
    final tempMessage = Message(
      id: tempId,
      chatId: _currentConversationId!,
      senderId: currentUserId,
      message: message.trim(),
      sentAt: DateTime.now(),
      synced: false,
    );
    
    _messages.insert(0, tempMessage);
    _messageStatuses[tempId] = MessageStatus.sending(tempId);
    notifyListeners();
    
    // Send message
    final success = await messagingService.sendMessage(
      conversationId: _currentConversationId!,
      senderId: currentUserId,
      message: message,
    );
    
    if (success) {
      _messageStatuses[tempId] = MessageStatus.sent(tempId);
    } else {
      _messageStatuses[tempId] = MessageStatus.failed(tempId, 'Failed to send');
      // Remove the temporary message on failure
      _messages.removeWhere((m) => m.id == tempId);
    }
    
    notifyListeners();
    return success;
  }
  
  /// Update typing indicator
  void updateTypingStatus(bool isTyping) {
    if (_currentConversationId == null) return;
    
    _isTyping = isTyping;
    
    if (isTyping) {
      // Cancel existing timer
      _typingTimer?.cancel();
      
      // Update typing indicator
      messagingService.updateTypingIndicator(
        _currentConversationId!,
        currentUserId,
        true,
      );
      
      // Set timer to stop typing after delay
      _typingTimer = Timer(MessagingConstants.typingTimeout, () {
        updateTypingStatus(false);
      });
    } else {
      // Cancel timer and update indicator
      _typingTimer?.cancel();
      messagingService.updateTypingIndicator(
        _currentConversationId!,
        currentUserId,
        false,
      );
    }
  }
  
  /// Get message status
  MessageStatus? getMessageStatus(String messageId) {
    return _messageStatuses[messageId];
  }
  
  /// Clear current conversation
  void clearConversation() {
    _currentConversationId = null;
    _currentRecipientId = null;
    _messages = [];
    _typingIndicator = null;
    _messageStatuses.clear();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}