import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../models/message.dart';
import '../../../../../models/user.dart';
import '../../../../../models/conversation_v2.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/real_time_user_service.dart';
import '../../../../../services/cloud_function_service.dart';
import '../../../../../services/conversation_service.dart';
import '../../../../../services/tab_visibility_manager/tab_visibility_manager.dart';
import '../models/conversation.dart' as OldConversation;
import '../models/typing_indicator.dart';
import '../models/message_status.dart';

/// Updated messaging service that uses the new conversation-centric structure
/// This is a wrapper that maintains compatibility with existing UI components
class MessagingServiceV2 extends ChangeNotifier {
  // Services
  final ConversationService _conversationService = ConversationService.instance;
  final AuthService _authService = AuthService();
  final RealTimeUserService _userService = RealTimeUserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final TabVisibilityManager _tabVisibilityManager = TabVisibilityManager();
  
  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  
  // Subscriptions
  StreamSubscription<List<ConversationV2>>? _conversationsSubscription;
  final Map<String, StreamSubscription<List<Message>>> _messageSubscriptions = {};
  final Map<String, StreamSubscription<Map<String, bool>>> _typingSubscriptions = {};
  
  // Cache for UI compatibility
  final Map<String, OldConversation.Conversation> _oldConversationsCache = {};
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, TypingIndicator> _typingIndicators = {};
  
  // Getters
  bool get isLoading => _isLoading || _conversationService.isLoading;
  String? get error => _error ?? _conversationService.error;
  bool get isInitialized => _isInitialized;
  Map<String, List<Message>> get messagesCache => Map.from(_messagesCache);
  Map<String, OldConversation.Conversation> get conversationsCache => Map.from(_oldConversationsCache);
  Map<String, TypingIndicator> get typingIndicators => Map.from(_typingIndicators);

  /// Initialize the messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get current user ID
      await _updateCurrentUserId();
      
      // Initialize tab visibility manager for web
      if (kIsWeb) {
        await _tabVisibilityManager.initialize();
        
        _tabVisibilityManager.onLeadershipChange('messaging_service_v2', (isLeader) {
          debugPrint('MessagingServiceV2: Leadership changed to $isLeader');
        });
        
        _tabVisibilityManager.onDataUpdate('messaging_service_v2', (data) {
          // Handle data updates from other tabs if needed
        });
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize messaging service: $e';
      notifyListeners();
    }
  }

  /// Update current user ID
  Future<void> _updateCurrentUserId() async {
    debugPrint('🔍 MessagingServiceV2._updateCurrentUserId - START');
    
    final user = _authService.currentUser;
    debugPrint('  Firebase Auth User: ${user?.uid}');
    
    if (user == null) {
      debugPrint('  ❌ No authenticated user');
      return;
    }
    
    final universityPath = _cloudFunctions.getCurrentUniversityPath();
    debugPrint('  University path: $universityPath');
    debugPrint('  Querying: $universityPath/data/users where firebase_uid == ${user.uid}');
    
    final userQuery = await FirebaseFirestore.instance
        .collection(universityPath)
        .doc('data')
        .collection('users')
        .where('firebase_uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    
    debugPrint('  Query result: ${userQuery.docs.length} documents found');
    
    if (userQuery.docs.isNotEmpty) {
      _currentUserId = userQuery.docs.first.id;
      debugPrint('  ✅ Found user document ID: $_currentUserId');
      
      // Log user data for debugging
      final userData = userQuery.docs.first.data();
      debugPrint('  User data keys: ${userData.keys.toList()}');
      debugPrint('  User name: ${userData['name']}');
      debugPrint('  User role: ${userData['user_type']}');
    } else {
      debugPrint('  ❌ No user document found');
    }
    
    debugPrint('🔍 MessagingServiceV2._updateCurrentUserId - END');
  }

  /// Convert ConversationV2 to old Conversation format for UI compatibility
  OldConversation.Conversation _convertToOldConversation(ConversationV2 conv) {
    final otherUserId = conv.getOtherParticipantId(_currentUserId!);
    if (otherUserId == null) {
      throw Exception('Invalid conversation: not a direct conversation');
    }
    
    final otherUserDetails = conv.participantDetails[otherUserId];
    final userSettings = conv.getUserSettings(_currentUserId!);
    
    return OldConversation.Conversation(
      id: conv.id,
      userId: otherUserId,
      userName: otherUserDetails?.name ?? otherUserId.replaceAll('_', ' '),
      userRole: otherUserDetails?.userType ?? 'unknown',
      lastMessage: conv.lastMessage?.text ?? '',
      lastMessageTime: conv.lastMessage?.timestamp,
      unreadCount: userSettings?.unreadCount ?? 0,
      isOnline: false, // TODO: Implement online status
    );
  }

  /// Listen to conversations for a user (returns old format for compatibility)
  Stream<List<OldConversation.Conversation>> getConversationsStream(String userId) async* {
    // Update current user ID if needed
    if (_currentUserId == null) {
      await _updateCurrentUserId();
    }
    
    // Use the new conversation service
    await for (var conversations in _conversationService.getConversationsStream()) {
      final oldFormatConversations = <OldConversation.Conversation>[];
      
      for (var conv in conversations) {
        try {
          final oldConv = _convertToOldConversation(conv);
          oldFormatConversations.add(oldConv);
          _oldConversationsCache[conv.id] = oldConv;
        } catch (e) {
          debugPrint('Error converting conversation ${conv.id}: $e');
        }
      }
      
      yield oldFormatConversations;
      notifyListeners();
    }
  }

  /// Listen to messages in a conversation
  Stream<List<Message>> getMessagesStream(String conversationId, int limit) {
    return _conversationService.getMessagesStream(conversationId, limit: limit)
        .map((messages) {
      _messagesCache[conversationId] = messages;
      notifyListeners();
      return messages;
    });
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final success = await _conversationService.sendMessage(
        conversationId: conversationId,
        message: message,
      );
      
      if (!success) {
        _error = 'Failed to send message';
      }
      
      return success;
    } catch (e) {
      _error = 'Error sending message: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to typing indicators
  Stream<TypingIndicator?> getTypingIndicatorStream(String conversationId, String userId) async* {
    await for (var typingStatus in _conversationService.getTypingIndicatorStream(conversationId)) {
      // Remove current user from typing status
      typingStatus.remove(userId);
      
      if (typingStatus.isEmpty) {
        yield null;
      } else {
        // Get user names for typing users
        final userNames = <String>[];
        for (var uid in typingStatus.keys) {
          final user = _userService.getUserById(uid);
          if (user != null) {
            userNames.add(user.name.split(' ').first);
          }
        }
        
        if (userNames.isNotEmpty) {
          yield TypingIndicator(
            conversationId: conversationId,
            userIds: typingStatus.keys.toList(),
            userNames: userNames,
          );
        } else {
          yield null;
        }
      }
    }
  }

  /// Update typing indicator
  Future<void> updateTypingIndicator(String conversationId, String userId, bool isTyping) async {
    await _conversationService.updateTypingIndicator(conversationId, isTyping);
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Get unread messages for this conversation
      final messages = _messagesCache[conversationId] ?? [];
      final unreadMessageIds = messages
          .where((msg) => msg.senderId != userId)
          .map((msg) => msg.id)
          .toList();
      
      if (unreadMessageIds.isNotEmpty) {
        await _conversationService.markMessagesAsRead(conversationId, unreadMessageIds);
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Archive a conversation
  Future<bool> archiveConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      archived: true,
    );
  }

  /// Unarchive a conversation
  Future<bool> unarchiveConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      archived: false,
    );
  }

  /// Pin a conversation
  Future<bool> pinConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      pinned: true,
    );
  }

  /// Unpin a conversation
  Future<bool> unpinConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      pinned: false,
    );
  }

  /// Mute notifications for a conversation
  Future<bool> muteConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      notificationsEnabled: false,
    );
  }

  /// Unmute notifications for a conversation
  Future<bool> unmuteConversation(String conversationId) async {
    return await _conversationService.updateConversationSettings(
      conversationId: conversationId,
      notificationsEnabled: true,
    );
  }

  /// Generate chat ID (for compatibility)
  static String generateChatId(String userId1, String userId2) {
    return ConversationService.generateConversationId(userId1, userId2);
  }

  /// Get or create conversation
  Future<String?> getOrCreateConversation(String user1Id, String user2Id) async {
    debugPrint('🔍 MessagingServiceV2.getOrCreateConversation - START');
    debugPrint('  user1Id: $user1Id');
    debugPrint('  user2Id: $user2Id');
    debugPrint('  currentUserId: $_currentUserId');
    
    try {
      // If we're using the new ensureConversationExists method
      final conversationId = await _conversationService.ensureConversationExists(user1Id, user2Id);
      
      if (conversationId != null) {
        debugPrint('  ✅ Conversation ensured: $conversationId');
      } else {
        debugPrint('  ❌ Failed to ensure conversation');
      }
      
      return conversationId;
    } catch (e, stackTrace) {
      debugPrint('  ❌ ERROR in getOrCreateConversation:');
      debugPrint('    Error: $e');
      debugPrint('    Stack: $stackTrace');
      return null;
    } finally {
      debugPrint('🔍 MessagingServiceV2.getOrCreateConversation - END');
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    for (var sub in _typingSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}