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
    debugPrint('MessageController: loadMessages called - conversationId: $conversationId, currentUserId: $currentUserId, recipientId: $recipientId');
    
    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      debugPrint('MessageController: Messages already loaded for this conversation');
      return; // Already loaded
    }
    
    _currentConversationId = conversationId;
    _currentRecipientId = recipientId;
    _messages = [];
    _messageLimit = MessagingConstants.initialMessageLoadCount;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    debugPrint('MessageController: Setting isLoading = true');
    
    // Cancel existing subscriptions
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    
    // Subscribe to messages
    debugPrint('MessageController: Subscribing to messages stream');
    
    // Add a timeout to prevent infinite loading
    Timer? loadingTimeout;
    loadingTimeout = Timer(const Duration(seconds: 10), () {
      if (_isLoading) {
        debugPrint('MessageController: Loading timeout - setting empty messages');
        _messages = [];
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
    
    _messagesSubscription = messagingService
        .getMessagesStream(conversationId, _messageLimit)
        .listen(
      (messages) {
        debugPrint('MessageController: Received ${messages.length} messages');
        loadingTimeout?.cancel();
        
        // Remove any temporary messages that now have real versions
        final tempMessageIds = _messages
            .where((m) => m.id.startsWith('temp_'))
            .map((m) => m.id)
            .toList();
        
        if (tempMessageIds.isNotEmpty) {
          debugPrint('Found ${tempMessageIds.length} temporary messages to clean up');
          // Remove temp messages that are no longer needed
          _messages.removeWhere((m) => m.id.startsWith('temp_') && m.synced);
          
          // Clear their statuses
          for (var tempId in tempMessageIds) {
            _messageStatuses.remove(tempId);
          }
        }
        
        _messages = messages;
        _hasMore = messages.length >= _messageLimit;
        _isLoading = false;
        _error = null;
        notifyListeners();
        
        // Mark messages as read
        messagingService.markMessagesAsRead(conversationId, currentUserId);
      },
      onError: (error) {
        debugPrint('MessageController: Error loading messages: $error');
        loadingTimeout?.cancel();
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
    debugPrint('=== MESSAGE SENDING DEBUG START ===');
    debugPrint('MessageController.sendMessage called with message: "$message"');
    debugPrint('Current conversation ID: $_currentConversationId');
    debugPrint('Current user ID (should be doc ID like Emerald_Nash): $currentUserId');
    
    if (_currentConversationId == null || message.trim().isEmpty) {
      debugPrint('FAILED: conversationId is null or message is empty');
      return false;
    }
    
    // Create temporary message ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('Created temporary message ID: $tempId');
    
    // Add message to list immediately (optimistic update)
    final tempMessage = Message(
      id: tempId,
      chatId: _currentConversationId!,
      senderId: currentUserId,
      message: message.trim(),
      sentAt: DateTime.now(),
      synced: false,
    );
    
    debugPrint('Adding temporary message to UI');
    _messages.insert(0, tempMessage);
    _messageStatuses[tempId] = MessageStatus.sending(tempId);
    notifyListeners();
    
    debugPrint('Calling messagingService.sendMessage...');
    final startTime = DateTime.now();
    
    // Send message
    final success = await messagingService.sendMessage(
      conversationId: _currentConversationId!,
      senderId: currentUserId,
      message: message,
    );
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    debugPrint('messagingService.sendMessage completed in ${duration}ms with success: $success');
    
    if (success) {
      debugPrint('Message sent successfully, updating status to sent');
      _messageStatuses[tempId] = MessageStatus.sent(tempId);
      
      // After 3 seconds, remove the temporary message status if it's still there
      Timer(const Duration(seconds: 3), () {
        if (_messageStatuses.containsKey(tempId)) {
          debugPrint('Removing temporary message status for $tempId after timeout');
          _messageStatuses.remove(tempId);
          notifyListeners();
        }
      });
    } else {
      debugPrint('Message send failed, updating status to failed');
      _messageStatuses[tempId] = MessageStatus.failed(tempId, 'Failed to send');
      // Remove the temporary message on failure
      _messages.removeWhere((m) => m.id == tempId);
    }
    
    debugPrint('Notifying listeners after status update');
    notifyListeners();
    debugPrint('=== MESSAGE SENDING DEBUG END ===');
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
    final status = _messageStatuses[messageId];
    if (status != null) {
      debugPrint('getMessageStatus for $messageId: ${status.status}');
    }
    return status;
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