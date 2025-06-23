import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/conversation_v2.dart';
import '../services/auth_service.dart';
import '../services/cloud_function_service.dart';

/// Service for managing conversations using the new conversation-centric structure
class ConversationService extends ChangeNotifier {
  static final ConversationService _instance = ConversationService._init();
  static ConversationService get instance => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  
  ConversationService._init();
  
  // State
  bool _isLoading = false;
  String? _error;
  
  // Subscriptions
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  
  // Cache
  final Map<String, ConversationV2> _conversationsCache = {};
  final Map<String, List<Message>> _messagesCache = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get university path from CloudFunctionService
  String get _universityPath => _cloudFunctions.getCurrentUniversityPath();
  
  /// Get the current user's ID (document ID, not Firebase UID)
  Future<String?> _getCurrentUserId() async {
    debugPrint('🔍 ConversationService._getCurrentUserId - START');
    
    final user = _authService.currentUser;
    debugPrint('  Firebase Auth User: ${user?.uid}');
    
    if (user == null) {
      debugPrint('  ❌ No authenticated user');
      return null;
    }
    
    // Get user document ID from users collection
    debugPrint('  Querying Firestore for user document...');
    debugPrint('  Collection path: $_universityPath/data/users');
    debugPrint('  Where firebase_uid == ${user.uid}');
    
    final userQuery = await _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('users')
        .where('firebase_uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    
    debugPrint('  Query result: ${userQuery.docs.length} documents found');
    
    if (userQuery.docs.isEmpty) {
      debugPrint('  ❌ No user document found for Firebase UID: ${user.uid}');
      return null;
    }
    
    final userId = userQuery.docs.first.id;
    debugPrint('  ✅ Found user document ID: $userId');
    debugPrint('🔍 ConversationService._getCurrentUserId - END');
    
    return userId;
  }
  
  /// Create a new conversation
  Future<String?> createConversation({
    required String user1Id,
    required String user2Id,
    String? mentorshipId,
  }) async {
    debugPrint('🔍 ConversationService.createConversation - START');
    debugPrint('  user1Id: $user1Id');
    debugPrint('  user2Id: $user2Id');
    debugPrint('  mentorshipId: $mentorshipId');
    debugPrint('  universityPath: $_universityPath');
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Log the exact parameters being sent
      final params = {
        'user1Id': user1Id,
        'user2Id': user2Id,
        if (mentorshipId != null) 'mentorshipId': mentorshipId,
      };
      debugPrint('  Cloud function parameters: $params');
      
      final result = await _cloudFunctions.createChatConversation(
        user1Id: user1Id,
        user2Id: user2Id,
        mentorshipId: mentorshipId,
      );
      
      debugPrint('  Cloud function response:');
      debugPrint('    Full response: $result');
      debugPrint('    Success: ${result['success']}');
      debugPrint('    Message: ${result['message']}');
      debugPrint('    ConversationId: ${result['conversationId']}');
      debugPrint('    Error details: ${result['error']}');
      
      if (result['success'] == true) {
        debugPrint('  ✅ Conversation created successfully');
        return result['conversationId'];
      } else {
        debugPrint('  ❌ Failed to create conversation');
        _error = result['message'] ?? 'Failed to create conversation';
        return null;
      }
    } catch (e, stackTrace) {
      _error = 'Error creating conversation: $e';
      debugPrint('  ❌ ERROR in createConversation:');
      debugPrint('    Error type: ${e.runtimeType}');
      debugPrint('    Error message: $e');
      debugPrint('    Stack trace: $stackTrace');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔍 ConversationService.createConversation - END');
    }
  }
  
  /// Get conversations stream for the current user
  Stream<List<ConversationV2>> getConversationsStream() async* {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }
    
    yield* _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ConversationV2.fromFirestore(doc))
          .toList();
      
      // Update cache
      for (var conv in conversations) {
        _conversationsCache[conv.id] = conv;
      }
      
      return conversations;
    });
  }
  
  /// Get a specific conversation
  Future<ConversationV2?> getConversation(String conversationId) async {
    debugPrint('🔍 ConversationService.getConversation - START');
    debugPrint('  conversationId: $conversationId');
    debugPrint('  universityPath: $_universityPath');
    
    try {
      // Check cache first
      if (_conversationsCache.containsKey(conversationId)) {
        debugPrint('  ✅ Found in cache');
        return _conversationsCache[conversationId];
      }
      
      debugPrint('  ❌ Not in cache, checking Firestore...');
      debugPrint('  Firestore path: $_universityPath/data/conversations/$conversationId');
      
      final doc = await _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      debugPrint('  Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        debugPrint('  ❌ Conversation not found in Firestore');
        return null;
      }
      
      debugPrint('  Document data: ${doc.data()}');
      
      final conversation = ConversationV2.fromFirestore(doc);
      _conversationsCache[conversationId] = conversation;
      
      debugPrint('  ✅ Conversation loaded successfully');
      debugPrint('    ID: ${conversation.id}');
      debugPrint('    Type: ${conversation.type}');
      debugPrint('    Participants: ${conversation.participants}');
      
      return conversation;
    } catch (e, stackTrace) {
      debugPrint('  ❌ ERROR getting conversation:');
      debugPrint('    Error type: ${e.runtimeType}');
      debugPrint('    Error message: $e');
      debugPrint('    Stack trace: $stackTrace');
      return null;
    } finally {
      debugPrint('🔍 ConversationService.getConversation - END');
    }
  }
  
  /// Get messages stream for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId, {int limit = 50}) {
    return _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Message.fromMap(data);
      }).toList();
      
      // Update cache
      _messagesCache[conversationId] = messages;
      
      return messages;
    });
  }
  
  /// Send a message using Cloud Function
  Future<bool> sendMessage({
    required String conversationId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? media,
  }) async {
    debugPrint('🔍 ConversationService.sendMessage - START');
    debugPrint('  conversationId: $conversationId');
    debugPrint('  message: $message');
    debugPrint('  type: $type');
    debugPrint('  media: $media');
    
    try {
      // Get current user ID
      final currentUserId = await _getCurrentUserId();
      debugPrint('  currentUserId: $currentUserId');
      
      if (currentUserId == null) {
        debugPrint('  ❌ No current user ID found');
        _error = 'User not authenticated';
        notifyListeners();
        return false;
      }
      
      final result = await _cloudFunctions.sendChatMessage(
        conversationId: conversationId,
        message: message,
        type: type,
        media: media,
      );
      
      debugPrint('  Cloud function response:');
      debugPrint('    Full response: $result');
      debugPrint('    Success: ${result['success']}');
      debugPrint('    Message: ${result['message']}');
      
      if (result['success'] == true) {
        debugPrint('  ✅ Message sent successfully');
        return true;
      } else {
        debugPrint('  ❌ Failed to send message');
        _error = result['message'] ?? 'Failed to send message';
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error sending message: $e';
      debugPrint('  ❌ ERROR in sendMessage:');
      debugPrint('    Error type: ${e.runtimeType}');
      debugPrint('    Error message: $e');
      debugPrint('    Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      debugPrint('🔍 ConversationService.sendMessage - END');
    }
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, List<String> messageIds) async {
    try {
      await _cloudFunctions.markChatMessagesRead(
        conversationId: conversationId,
        messageIds: messageIds,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
  
  /// Update conversation settings
  Future<bool> updateConversationSettings({
    required String conversationId,
    bool? notificationsEnabled,
    bool? archived,
    bool? pinned,
    String? customNickname,
  }) async {
    try {
      final settings = <String, dynamic>{};
      if (notificationsEnabled != null) settings['notifications_enabled'] = notificationsEnabled;
      if (archived != null) settings['archived'] = archived;
      if (pinned != null) settings['pinned'] = pinned;
      if (customNickname != null) settings['custom_nickname'] = customNickname;
      
      final result = await _cloudFunctions.updateChatSettings(
        conversationId: conversationId,
        settings: settings,
      );
      
      return result['success'] == true;
    } catch (e) {
      _error = 'Error updating conversation settings: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }
  
  /// Generate conversation ID from two user IDs
  /// The IDs are sorted alphabetically to ensure consistency
  /// regardless of the order they're provided in.
  /// Example: generateConversationId("Emerald_Nash", "Dasarathi_Narayanan")
  /// Returns: "Dasarathi_Narayanan__Emerald_Nash"
  static String generateConversationId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}__${sortedIds[1]}';
  }
  
  /// Get or create conversation between two users
  Future<String?> getOrCreateConversation(String user1Id, String user2Id) async {
    debugPrint('🔍 ConversationService.getOrCreateConversation - START');
    debugPrint('  user1Id: $user1Id');
    debugPrint('  user2Id: $user2Id');
    
    // Generate conversation ID
    final conversationId = generateConversationId(user1Id, user2Id);
    debugPrint('  Generated conversationId: $conversationId');
    
    // Check if conversation exists
    debugPrint('  Checking if conversation exists...');
    final existingConversation = await getConversation(conversationId);
    if (existingConversation != null) {
      debugPrint('  ✅ Conversation already exists');
      return conversationId;
    }
    
    debugPrint('  ❌ Conversation does not exist, creating new one...');
    // Create new conversation
    final newConversationId = await createConversation(
      user1Id: user1Id,
      user2Id: user2Id,
    );
    debugPrint('  Creation result: ${newConversationId != null ? '✅ Success' : '❌ Failed'}');
    debugPrint('🔍 ConversationService.getOrCreateConversation - END');
    return newConversationId;
  }
  
  /// Ensure a conversation exists (with detailed debugging)
  Future<String?> ensureConversationExists(String user1Id, String user2Id) async {
    debugPrint('🔍 ConversationService.ensureConversationExists - START');
    debugPrint('  user1Id: $user1Id');
    debugPrint('  user2Id: $user2Id');
    debugPrint('  universityPath: $_universityPath');
    
    try {
      // Generate conversation ID
      final conversationId = generateConversationId(user1Id, user2Id);
      debugPrint('  Generated conversationId: $conversationId');
      
      // Build the full Firestore path
      final conversationPath = '$_universityPath/data/conversations/$conversationId';
      debugPrint('  Full Firestore path: $conversationPath');
      
      // Check if conversation exists in Firestore
      debugPrint('  Checking Firestore for conversation...');
      final docRef = _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('conversations')
          .doc(conversationId);
      
      final doc = await docRef.get();
      debugPrint('  Firestore check result: ${doc.exists ? 'EXISTS' : 'DOES NOT EXIST'}');
      
      if (doc.exists) {
        debugPrint('  ✅ Conversation found in Firestore');
        
        // Verify it has the expected structure
        final data = doc.data();
        if (data != null) {
          debugPrint('  Conversation data keys: ${data.keys.toList()}');
          debugPrint('  Participants: ${data['participants']}');
          debugPrint('  Type: ${data['type']}');
          debugPrint('  Created at: ${data['created_at']}');
        }
        
        return conversationId;
      }
      
      debugPrint('  ❌ Conversation not found, attempting to create...');
      
      // Log the parameters being sent to cloud function
      final params = {
        'user1Id': user1Id,
        'user2Id': user2Id,
      };
      debugPrint('  Cloud function parameters: $params');
      
      // Create new conversation using cloud function
      final result = await _cloudFunctions.createChatConversation(
        user1Id: user1Id,
        user2Id: user2Id,
      );
      
      debugPrint('  Cloud function response:');
      debugPrint('    Full result: $result');
      debugPrint('    Success: ${result['success']}');
      debugPrint('    Message: ${result['message']}');
      debugPrint('    ConversationId: ${result['conversationId']}');
      
      if (result['success'] == true && result['conversationId'] != null) {
        debugPrint('  ✅ Conversation created successfully');
        return result['conversationId'];
      } else {
        debugPrint('  ❌ Failed to create conversation');
        _error = result['message'] ?? 'Failed to create conversation';
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('  ❌ ERROR in ensureConversationExists:');
      debugPrint('    Error type: ${e.runtimeType}');
      debugPrint('    Error message: $e');
      debugPrint('    Stack trace: $stackTrace');
      _error = 'Error ensuring conversation exists: $e';
      notifyListeners();
      return null;
    } finally {
      debugPrint('🔍 ConversationService.ensureConversationExists - END');
    }
  }
  
  /// Listen to typing indicators
  Stream<Map<String, bool>> getTypingIndicatorStream(String conversationId) {
    return _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId)
        .collection('typing_status')
        .snapshots()
        .map((snapshot) {
      final typingStatus = <String, bool>{};
      final now = DateTime.now();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isTyping = data['is_typing'] ?? false;
        final lastUpdated = (data['last_updated'] as Timestamp?)?.toDate();
        
        // Only show typing if updated within last 5 seconds
        if (isTyping && lastUpdated != null && 
            now.difference(lastUpdated).inSeconds < 5) {
          typingStatus[doc.id] = true;
        }
      }
      
      return typingStatus;
    });
  }
  
  /// Update typing indicator
  Future<void> updateTypingIndicator(String conversationId, bool isTyping) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    
    try {
      await _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('conversations')
          .doc(conversationId)
          .collection('typing_status')
          .doc(userId)
          .set({
        'is_typing': isTyping,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating typing indicator: $e');
    }
  }
  
  /// Clear cache
  void clearCache() {
    _conversationsCache.clear();
    _messagesCache.clear();
    notifyListeners();
  }
  
  /// Clean up resources
  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}