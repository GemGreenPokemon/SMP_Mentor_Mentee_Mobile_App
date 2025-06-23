import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/cloud_function_service.dart';

/// Service to migrate messages from user-centric to conversation-centric structure
class MessageMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  
  // Migration state
  bool _isRunning = false;
  int _totalMessages = 0;
  int _migratedMessages = 0;
  int _failedMessages = 0;
  final List<String> _errors = [];
  
  // Getters
  bool get isRunning => _isRunning;
  int get totalMessages => _totalMessages;
  int get migratedMessages => _migratedMessages;
  int get failedMessages => _failedMessages;
  List<String> get errors => List.from(_errors);
  double get progress => _totalMessages > 0 ? _migratedMessages / _totalMessages : 0.0;
  
  /// Get university path
  String get _universityPath => _cloudFunctions.getCurrentUniversityPath();
  
  /// Dry run - analyze what would be migrated without making changes
  Future<Map<String, dynamic>> analyzeMigration() async {
    debugPrint('Starting migration analysis...');
    
    try {
      // Get all users
      final usersSnapshot = await _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .get();
      
      int totalUsers = usersSnapshot.docs.length;
      int totalMessages = 0;
      Map<String, int> conversationMessageCounts = {};
      Set<String> uniqueConversations = {};
      
      // Analyze each user's messages
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get messages subcollection
        final messagesSnapshot = await _firestore
            .collection(_universityPath)
            .doc('data')
            .collection('users')
            .doc(userId)
            .collection('messages')
            .get();
        
        totalMessages += messagesSnapshot.docs.length;
        
        // Count messages per conversation
        for (var messageDoc in messagesSnapshot.docs) {
          final data = messageDoc.data();
          final chatId = data['chat_id'] as String?;
          
          if (chatId != null) {
            uniqueConversations.add(chatId);
            conversationMessageCounts[chatId] = (conversationMessageCounts[chatId] ?? 0) + 1;
          }
        }
      }
      
      // Calculate duplicate messages (messages that exist in both users' collections)
      int duplicateMessages = 0;
      for (var count in conversationMessageCounts.values) {
        if (count > 1) {
          // Assuming each message is stored twice (sender and recipient)
          duplicateMessages += count ~/ 2;
        }
      }
      
      return {
        'totalUsers': totalUsers,
        'totalMessages': totalMessages,
        'uniqueConversations': uniqueConversations.length,
        'duplicateMessages': duplicateMessages,
        'estimatedUniqueMessages': totalMessages - duplicateMessages,
        'conversationBreakdown': conversationMessageCounts,
      };
    } catch (e) {
      debugPrint('Error analyzing migration: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Migrate messages for a specific conversation
  Future<bool> migrateConversation(String conversationId, {bool dryRun = false}) async {
    debugPrint('Migrating conversation: $conversationId (dryRun: $dryRun)');
    
    try {
      // Parse user IDs from conversation ID
      final parts = conversationId.split('__');
      if (parts.length != 2) {
        throw Exception('Invalid conversation ID format');
      }
      
      final user1Id = parts[0];
      final user2Id = parts[1];
      
      // Check if conversation already exists
      final conversationRef = _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('conversations')
          .doc(conversationId);
      
      final conversationDoc = await conversationRef.get();
      if (conversationDoc.exists && !dryRun) {
        debugPrint('Conversation already exists, skipping creation');
      } else if (!dryRun) {
        // Create conversation document
        await _createConversation(conversationId, user1Id, user2Id);
      }
      
      // Collect all messages from both users
      final allMessages = <Message>[];
      final processedMessageIds = <String>{};
      
      // Get messages from user1
      final user1Messages = await _getUserMessages(user1Id, conversationId);
      allMessages.addAll(user1Messages);
      
      // Get messages from user2
      final user2Messages = await _getUserMessages(user2Id, conversationId);
      
      // Merge messages, avoiding duplicates
      for (var message in user2Messages) {
        // Check if we already have this message (based on content and timestamp)
        final isDuplicate = allMessages.any((m) => 
          m.message == message.message && 
          m.sentAt == message.sentAt &&
          m.senderId == message.senderId
        );
        
        if (!isDuplicate) {
          allMessages.add(message);
        }
      }
      
      // Sort messages by timestamp
      allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      debugPrint('Found ${allMessages.length} unique messages to migrate');
      
      if (!dryRun) {
        // Migrate messages to conversation subcollection
        final batch = _firestore.batch();
        int batchCount = 0;
        
        for (var message in allMessages) {
          final messageRef = conversationRef.collection('messages').doc();
          
          batch.set(messageRef, {
            'sender_id': message.senderId,
            'message': message.message,
            'sent_at': Timestamp.fromDate(message.sentAt),
            'type': 'text',
            'status': 'read', // Assume all old messages are read
            'read_by': {
              user1Id: Timestamp.fromDate(message.sentAt),
              user2Id: Timestamp.fromDate(message.sentAt),
            },
            'reactions': {},
            'metadata': {
              'migrated': true,
              'migrated_at': FieldValue.serverTimestamp(),
              'original_id': message.id,
            },
          });
          
          batchCount++;
          
          // Commit batch every 500 documents (Firestore limit)
          if (batchCount >= 500) {
            await batch.commit();
            batchCount = 0;
          }
        }
        
        // Commit remaining documents
        if (batchCount > 0) {
          await batch.commit();
        }
        
        // Update conversation with last message
        if (allMessages.isNotEmpty) {
          final lastMessage = allMessages.last;
          await conversationRef.update({
            'last_message': {
              'text': lastMessage.message,
              'sender_id': lastMessage.senderId,
              'timestamp': Timestamp.fromDate(lastMessage.sentAt),
            },
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error migrating conversation $conversationId: $e');
      _errors.add('Conversation $conversationId: ${e.toString()}');
      return false;
    }
  }
  
  /// Create a new conversation document
  Future<void> _createConversation(String conversationId, String user1Id, String user2Id) async {
    // Get user details
    final user1Doc = await _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('users')
        .doc(user1Id)
        .get();
    
    final user2Doc = await _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('users')
        .doc(user2Id)
        .get();
    
    if (!user1Doc.exists || !user2Doc.exists) {
      throw Exception('One or both users not found');
    }
    
    final user1Data = user1Doc.data()!;
    final user2Data = user2Doc.data()!;
    
    // Create conversation document
    await _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId)
        .set({
      'participants': [user1Id, user2Id],
      'participant_details': {
        user1Id: {
          'name': user1Data['name'] ?? user1Id,
          'role': user1Data['role'] ?? user1Data['user_type'] ?? 'unknown',
          'joined_at': FieldValue.serverTimestamp(),
        },
        user2Id: {
          'name': user2Data['name'] ?? user2Id,
          'role': user2Data['role'] ?? user2Data['user_type'] ?? 'unknown',
          'joined_at': FieldValue.serverTimestamp(),
        },
      },
      'last_message': null,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'type': 'direct',
      'metadata': {
        'migrated': true,
        'migrated_at': FieldValue.serverTimestamp(),
      },
      'user_settings': {
        user1Id: {
          'last_read': FieldValue.serverTimestamp(),
          'unread_count': 0,
          'notifications_enabled': true,
          'archived': false,
          'pinned': false,
          'custom_nickname': null,
        },
        user2Id: {
          'last_read': FieldValue.serverTimestamp(),
          'unread_count': 0,
          'notifications_enabled': true,
          'archived': false,
          'pinned': false,
          'custom_nickname': null,
        },
      },
    });
  }
  
  /// Get messages for a user in a specific conversation
  Future<List<Message>> _getUserMessages(String userId, String conversationId) async {
    final messagesSnapshot = await _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('users')
        .doc(userId)
        .collection('messages')
        .where('chat_id', isEqualTo: conversationId)
        .get();
    
    return messagesSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Message.fromMap(data);
    }).toList();
  }
  
  /// Migrate all conversations
  Future<Map<String, dynamic>> migrateAllConversations({
    bool dryRun = false,
    void Function(double progress, String status)? onProgress,
  }) async {
    if (_isRunning) {
      return {'error': 'Migration already in progress'};
    }
    
    _isRunning = true;
    _totalMessages = 0;
    _migratedMessages = 0;
    _failedMessages = 0;
    _errors.clear();
    
    try {
      // First, analyze what needs to be migrated
      final analysis = await analyzeMigration();
      if (analysis.containsKey('error')) {
        return analysis;
      }
      
      final uniqueConversations = analysis['uniqueConversations'] as int;
      final conversationBreakdown = analysis['conversationBreakdown'] as Map<String, int>;
      
      onProgress?.call(0.0, 'Starting migration of $uniqueConversations conversations...');
      
      int processedConversations = 0;
      
      // Migrate each conversation
      for (var conversationId in conversationBreakdown.keys) {
        final messageCount = conversationBreakdown[conversationId]!;
        
        onProgress?.call(
          processedConversations / uniqueConversations,
          'Migrating conversation $conversationId ($messageCount messages)...',
        );
        
        final success = await migrateConversation(conversationId, dryRun: dryRun);
        
        if (success) {
          _migratedMessages += messageCount;
        } else {
          _failedMessages += messageCount;
        }
        
        processedConversations++;
      }
      
      onProgress?.call(1.0, 'Migration completed!');
      
      return {
        'success': true,
        'totalConversations': uniqueConversations,
        'migratedMessages': _migratedMessages,
        'failedMessages': _failedMessages,
        'errors': _errors,
        'dryRun': dryRun,
      };
    } catch (e) {
      debugPrint('Error during migration: $e');
      return {'error': e.toString()};
    } finally {
      _isRunning = false;
    }
  }
  
  /// Clean up old messages after successful migration
  Future<bool> cleanupOldMessages({required String userId, required String conversationId}) async {
    try {
      // Get all messages for this conversation from user's subcollection
      final messagesSnapshot = await _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .doc(userId)
          .collection('messages')
          .where('chat_id', isEqualTo: conversationId)
          .get();
      
      // Delete in batches
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      debugPrint('Cleaned up ${messagesSnapshot.docs.length} messages for user $userId in conversation $conversationId');
      return true;
    } catch (e) {
      debugPrint('Error cleaning up messages: $e');
      return false;
    }
  }
}