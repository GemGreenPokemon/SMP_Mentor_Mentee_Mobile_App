import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/local_database_service.dart';
import '../utils/test_mode_manager.dart';

class MessagingService extends ChangeNotifier {
  static final MessagingService instance = MessagingService._init();
  final _localDb = LocalDatabaseService.instance;
  
  MessagingService._init();
  
  // State management
  bool _hasInitialized = false;
  bool _isLoading = false;
  
  // Database data
  Map<String, List<Message>> _dbConversations = {};
  Map<String, int> _dbUnreadCounts = {};
  
  // Mock data
  final Map<String, List<Message>> _mockConversations = {};
  final Map<String, int> _mockUnreadCounts = {};
  
  // Loading state
  bool get isLoading => _isLoading;
  
  /// Returns whether we should use database or mock data
  bool get _shouldUseDatabase {
    return TestModeManager.isTestMode && 
           TestModeManager.hasCompleteTestData &&
           _hasInitialized;
  }
  
  /// Initialize database data if in test mode
  Future<void> initialize() async {
    if (!TestModeManager.isTestMode || !TestModeManager.hasCompleteTestData) {
      _hasInitialized = true;
      _initializeMockData();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadDatabaseData();
      _hasInitialized = true;
    } catch (e) {
      debugPrint('Error loading messaging data from database: $e');
      _initializeMockData();
      _hasInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load all messages from database
  Future<void> _loadDatabaseData() async {
    if (!TestModeManager.hasCompleteTestData) return;
    
    final mentorId = TestModeManager.currentTestMentor!.id;
    final menteeId = TestModeManager.currentTestMentee!.id;
    
    // Generate chat ID
    final chatId = '${mentorId}__${menteeId}';
    
    debugPrint('MessagingService._loadDatabaseData:');
    debugPrint('  mentorId: $mentorId');
    debugPrint('  menteeId: $menteeId');
    debugPrint('  chatId: $chatId');
    
    // Load messages for this chat
    final messages = await _localDb.getMessagesByChat(chatId);
    
    debugPrint('  Loaded ${messages.length} messages from database');
    
    if (messages.isNotEmpty) {
      _dbConversations[chatId] = messages;
    } else {
      // Initialize empty conversation
      _dbConversations[chatId] = [];
    }
    
    // Calculate unread counts (for now, assume all read)
    _dbUnreadCounts[chatId] = 0;
  }
  
  /// Initialize mock data for non-test mode
  void _initializeMockData() {
    // Create some mock messages
    final now = DateTime.now();
    _mockConversations['mock_chat'] = [
      Message(
        id: '1',
        chatId: 'mock_chat',
        senderId: 'mentor',
        message: 'Hi! Welcome to the mentorship program.',
        sentAt: now.subtract(const Duration(hours: 2)),
      ),
      Message(
        id: '2',
        chatId: 'mock_chat',
        senderId: 'mentee',
        message: 'Thank you! I\'m excited to get started.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      Message(
        id: '3',
        chatId: 'mock_chat',
        senderId: 'mentor',
        message: 'Great! Let\'s schedule our first meeting.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ];
    _mockUnreadCounts['mock_chat'] = 0;
  }
  
  /// Get messages for a specific chat (respects user visibility)
  Future<List<Message>> getMessagesForUser(String userId1, String userId2, String currentUserId) async {
    // Generate consistent chat ID
    final chatId = generateChatId(userId1, userId2);
    
    debugPrint('MessagingService.getMessagesForUser:');
    debugPrint('  userId1: $userId1');
    debugPrint('  userId2: $userId2');
    debugPrint('  currentUserId: $currentUserId');
    debugPrint('  chatId: $chatId');
    debugPrint('  shouldUseDatabase: $_shouldUseDatabase');
    
    if (_shouldUseDatabase) {
      // Get only visible messages for this user
      final messages = await _localDb.getVisibleMessagesByChat(chatId, currentUserId);
      debugPrint('  Found ${messages.length} visible messages for user');
      return messages;
    } else {
      final messages = _mockConversations['mock_chat'] ?? [];
      debugPrint('  Returning ${messages.length} mock messages');
      return messages;
    }
  }
  
  /// Get messages for a specific chat (gets all messages - for backward compatibility)
  List<Message> getMessages(String userId1, String userId2) {
    // Generate consistent chat ID
    final chatId = generateChatId(userId1, userId2);
    
    debugPrint('MessagingService.getMessages:');
    debugPrint('  userId1: $userId1');
    debugPrint('  userId2: $userId2');
    debugPrint('  chatId: $chatId');
    debugPrint('  shouldUseDatabase: $_shouldUseDatabase');
    
    if (_shouldUseDatabase) {
      final messages = _dbConversations[chatId] ?? [];
      debugPrint('  Found ${messages.length} messages in database');
      return messages;
    } else {
      final messages = _mockConversations['mock_chat'] ?? [];
      debugPrint('  Returning ${messages.length} mock messages');
      return messages;
    }
  }
  
  /// Send a new message
  Future<bool> sendMessage({
    required String senderId,
    required String recipientId,
    required String messageText,
  }) async {
    try {
      final chatId = generateChatId(senderId, recipientId);
      
      debugPrint('MessagingService.sendMessage:');
      debugPrint('  senderId: $senderId');
      debugPrint('  recipientId: $recipientId');
      debugPrint('  chatId: $chatId');
      debugPrint('  message: $messageText');
      debugPrint('  shouldUseDatabase: $_shouldUseDatabase');
      
      final message = Message(
        id: _localDb.generateId(),
        chatId: chatId,
        senderId: senderId,
        message: messageText,
        sentAt: DateTime.now(),
      );
      
      if (_shouldUseDatabase) {
        // Save to database
        await _localDb.createMessage(message);
        debugPrint('  Message saved to database');
        
        // Update local cache
        _dbConversations[chatId] ??= [];
        _dbConversations[chatId]!.add(message);
        debugPrint('  Message added to cache. Total messages: ${_dbConversations[chatId]!.length}');
      } else {
        // Add to mock data
        _mockConversations['mock_chat'] ??= [];
        _mockConversations['mock_chat']!.add(message);
        debugPrint('  Message added to mock data');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }
  
  /// Get unread message count for a user
  int getUnreadCount(String userId) {
    // For now, return 0 as we haven't implemented read tracking
    return 0;
  }
  
  /// Mark messages as read
  Future<void> markAsRead(String chatId) async {
    if (_shouldUseDatabase) {
      _dbUnreadCounts[chatId] = 0;
    } else {
      _mockUnreadCounts['mock_chat'] = 0;
    }
    notifyListeners();
  }
  
  /// Generate consistent chat ID
  String generateChatId(String userId1, String userId2) {
    // Always put mentor ID first for consistency
    if (TestModeManager.isTestMode && TestModeManager.hasCompleteTestData) {
      final mentorId = TestModeManager.currentTestMentor!.id;
      final menteeId = TestModeManager.currentTestMentee!.id;
      
      // Ensure consistent ordering - mentor ID always first
      if (userId1 == mentorId || userId2 == mentorId) {
        return '${mentorId}__${menteeId}';
      }
      
      // If neither user is the current test mentor, use alphabetical ordering
      final sorted = [userId1, userId2]..sort();
      return '${sorted[0]}__${sorted[1]}';
    }
    // For mock data
    return 'mock_chat';
  }
  
  /// Get recent conversations for a user
  List<Map<String, dynamic>> getRecentConversations(String userId) {
    final conversations = <Map<String, dynamic>>[];
    
    if (_shouldUseDatabase) {
      // For test mode, return the current mentor-mentee conversation
      if (TestModeManager.hasCompleteTestData) {
        final chatId = generateChatId(
          TestModeManager.currentTestMentor!.id,
          TestModeManager.currentTestMentee!.id,
        );
        
        final messages = _dbConversations[chatId] ?? [];
        if (messages.isNotEmpty) {
          final lastMessage = messages.last;
          final otherUser = lastMessage.senderId == userId
              ? TestModeManager.currentTestMentee!
              : TestModeManager.currentTestMentor!;
          
          conversations.add({
            'chatId': chatId,
            'otherUser': otherUser,
            'lastMessage': lastMessage.message,
            'lastMessageTime': lastMessage.sentAt,
            'unreadCount': _dbUnreadCounts[chatId] ?? 0,
          });
        }
      }
    } else {
      // Return mock conversation
      final messages = _mockConversations['mock_chat'] ?? [];
      if (messages.isNotEmpty) {
        conversations.add({
          'chatId': 'mock_chat',
          'otherUser': User(
            id: 'mock_user',
            name: 'Mock User',
            email: 'mock@example.com',
            userType: 'mentor',
            createdAt: DateTime.now(),
          ),
          'lastMessage': messages.last.message,
          'lastMessageTime': messages.last.sentAt,
          'unreadCount': 0,
        });
      }
    }
    
    return conversations;
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await initialize();
  }
  
  /// Clear all messages for the current user (hide messages, not delete)
  Future<void> clearMessagesForCurrentUser(String currentUserId) async {
    if (_shouldUseDatabase && TestModeManager.hasCompleteTestData) {
      final chatId = generateChatId(
        TestModeManager.currentTestMentor!.id,
        TestModeManager.currentTestMentee!.id,
      );
      
      // Hide messages for this user
      await _localDb.hideMessagesForUser(chatId, currentUserId);
      
      // Reload to update the view
      await _loadDatabaseData();
    } else {
      // Clear mock data
      _mockConversations['mock_chat'] = [];
      _mockUnreadCounts['mock_chat'] = 0;
    }
    
    notifyListeners();
  }
  
  /// Clear all messages (for testing/debug only - actually deletes)
  Future<void> clearAllMessages() async {
    if (_shouldUseDatabase && TestModeManager.hasCompleteTestData) {
      final chatId = generateChatId(
        TestModeManager.currentTestMentor!.id,
        TestModeManager.currentTestMentee!.id,
      );
      
      // Clear from database
      final messages = await _localDb.getMessagesByChat(chatId);
      for (final message in messages) {
        await _localDb.database.then((db) => db.delete(
          'messages',
          where: 'id = ?',
          whereArgs: [message.id],
        ));
      }
      
      // Clear from cache
      _dbConversations[chatId] = [];
      _dbUnreadCounts[chatId] = 0;
    } else {
      // Clear mock data
      _mockConversations['mock_chat'] = [];
      _mockUnreadCounts['mock_chat'] = 0;
    }
    
    notifyListeners();
  }
  
  /// Get message count for current chat
  int getMessageCount() {
    if (_shouldUseDatabase && TestModeManager.hasCompleteTestData) {
      final chatId = generateChatId(
        TestModeManager.currentTestMentor!.id,
        TestModeManager.currentTestMentee!.id,
      );
      return _dbConversations[chatId]?.length ?? 0;
    }
    return _mockConversations['mock_chat']?.length ?? 0;
  }
}