import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../models/message.dart';
import '../../../../../models/user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/real_time_user_service.dart';
import '../../../../../services/cloud_function_service.dart';
import '../../../../../services/tab_visibility_manager/tab_visibility_manager.dart';
import '../models/conversation.dart';
import '../models/typing_indicator.dart';
import '../models/message_status.dart';

class MessagingService extends ChangeNotifier {
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final RealTimeUserService _userService = RealTimeUserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  final TabVisibilityManager _tabVisibilityManager = TabVisibilityManager();
  
  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // Subscriptions
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot>> _typingSubscriptions = {};
  
  // Cache
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, Conversation> _conversationsCache = {};
  final Map<String, TypingIndicator> _typingIndicators = {};
  DateTime? _lastFetchTime;
  
  // Get university path from CloudFunctionService
  String get _universityPath {
    final path = _cloudFunctions.getCurrentUniversityPath();
    debugPrint('CLOUD FUNCTION: getCurrentUniversityPath() returned: "$path"');
    return path;
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  Map<String, List<Message>> get messagesCache => Map.from(_messagesCache);
  Map<String, Conversation> get conversationsCache => Map.from(_conversationsCache);
  Map<String, TypingIndicator> get typingIndicators => Map.from(_typingIndicators);

  /// Initialize the messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize tab visibility manager for web
      if (kIsWeb) {
        await _tabVisibilityManager.initialize();
        
        // Listen for leadership changes
        _tabVisibilityManager.onLeadershipChange('messaging_service', (isLeader) {
          debugPrint('MessagingService: Leadership changed to $isLeader');
          if (isLeader && _lastFetchTime == null) {
            // Became leader and no data yet, start listening
            _startListening();
          }
        });
        
        // Listen for data updates from other tabs
        _tabVisibilityManager.onDataUpdate('messaging_service', (data) {
          if (data['type'] == 'messages_update') {
            _handleMessagesUpdate(data['conversationId'], data['messages']);
          } else if (data['type'] == 'conversations_update') {
            _handleConversationsUpdate(data['conversations']);
          }
        });
        
        _isInitialized = true;
        
        // Only start listening if we're the leader tab
        if (_tabVisibilityManager.isLeader) {
          _startListening();
        }
      } else {
        // Non-web platforms always listen
        _isInitialized = true;
        _startListening();
      }
    } catch (e) {
      _error = 'Failed to initialize messaging service: $e';
      notifyListeners();
    }
  }

  /// Start listening to real-time updates
  void _startListening() {
    debugPrint('MessagingService: Starting real-time listeners');
    _lastFetchTime = DateTime.now();
  }

  /// Listen to conversations for a user
  Stream<List<Conversation>> getConversationsStream(String userId) {
    final controller = StreamController<List<Conversation>>.broadcast();
    
    // Cancel existing subscription if any
    _conversationsSubscription?.cancel();
    
    // Query based on user type - for now assume mentor
    String userType = 'mentor'; // default
    
    debugPrint('Getting conversations for user: $userId as $userType');
    
    Query query;
    
    if (userType == 'mentor') {
      // For mentors, get conversations where they are the mentor
      query = _firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('mentorships')
          .where('mentor_id', isEqualTo: userId);
    } else {
      // For mentees, get conversations where they are the mentee
      query = _firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('mentorships')
          .where('mentee_id', isEqualTo: userId);
    }
    
    _conversationsSubscription = query.snapshots().listen(
      (snapshot) async {
        final conversations = <Conversation>[];
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final mentorId = data['mentor_id'] as String;
          final menteeId = data['mentee_id'] as String;
          final otherUserId = userId == mentorId ? menteeId : mentorId;
          
          // Generate chat ID first
          final chatId = _generateChatId(mentorId, menteeId);
          
          // Get user details
          final otherUser = _userService.getUserById(otherUserId);
          if (otherUser == null) {
            debugPrint('User not found in RealTimeUserService: $otherUserId');
            // Create a basic user object for now
            final basicConversation = Conversation(
              id: chatId,
              userId: otherUserId,
              userName: otherUserId.replaceAll('_', ' '), // Convert ID to name
              userRole: userId == mentorId ? 'mentee' : 'mentor',
              lastMessage: '',
              lastMessageTime: null,
              unreadCount: 0,
              isOnline: false,
            );
            conversations.add(basicConversation);
            continue;
          }
          
          // Get last message
          final lastMessage = await _getLastMessage(chatId);
          
          conversations.add(Conversation(
            id: chatId,
            userId: otherUserId,
            userName: otherUser.name,
            userRole: otherUser.userType,
            lastMessage: lastMessage?.message ?? '',
            lastMessageTime: lastMessage?.sentAt,
            unreadCount: 0, // TODO: Implement unread count
            isOnline: false, // TODO: Implement online status
          ));
        }
        
        // Update cache
        for (var conv in conversations) {
          _conversationsCache[conv.id] = conv;
        }
        
        // Share data with other tabs
        if (kIsWeb && _tabVisibilityManager.isLeader) {
          _tabVisibilityManager.shareData('messaging_service', {
            'type': 'conversations_update',
            'conversations': conversations.map((c) => c.toMap()).toList(),
          });
        }
        
        controller.add(conversations);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading conversations: $error');
        _error = 'Failed to load conversations';
        controller.addError(error);
        notifyListeners();
      },
    );
    
    return controller.stream;
  }

  /// Listen to messages in a conversation
  Stream<List<Message>> getMessagesStream(String conversationId, int limit) {
    final controller = StreamController<List<Message>>.broadcast();
    
    // Cancel existing subscription for this conversation
    _messageSubscriptions[conversationId]?.cancel();
    
    // Get the current user ID from the conversation controller or auth service
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      controller.addError('User not authenticated');
      return controller.stream;
    }
    
    // We need to get the user's document ID to query their messages
    // For now, we'll query based on the current user's messages subcollection
    // The conversationId tells us which chat to filter for
    
    // First, get the current user's document ID
    _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('users')
        .where('firebase_uid', isEqualTo: currentUser.uid)
        .limit(1)
        .get()
        .then((userSnapshot) {
      if (userSnapshot.docs.isEmpty) {
        controller.addError('User document not found');
        return;
      }
      
      final userDocId = userSnapshot.docs.first.id;
      debugPrint('Loading messages for user $userDocId in conversation $conversationId');
      
      // Listen to messages from the user's subcollection
      try {
        // Debug the exact path being queried
        final messagesPath = '/$_universityPath/data/users/$userDocId/messages';
        debugPrint('CLOUD FUNCTION: Querying messages from path: $messagesPath');
        debugPrint('CLOUD FUNCTION: Looking for chat_id: $conversationId');
        
        // First check if the messages subcollection exists
        _messageSubscriptions[conversationId] = _firestore
            .collection(_universityPath)
            .doc('data')
            .collection('users')
            .doc(userDocId)
            .collection('messages')
            .where('chat_id', isEqualTo: conversationId)
            .snapshots()
            .listen(
          (snapshot) {
            List<Message> messages = [];
            
            debugPrint('CLOUD FUNCTION: Found ${snapshot.docs.length} messages in query');
            
            if (snapshot.docs.isNotEmpty) {
              // Sort messages by sent_at in memory to avoid index issues
              final sortedDocs = List.from(snapshot.docs);
              sortedDocs.sort((a, b) {
                final aTime = a.data()['sent_at'] as Timestamp?;
                final bTime = b.data()['sent_at'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime); // Descending order
              });
              
              // Take only the requested limit
              final limitedDocs = sortedDocs.take(limit);
              
              messages = limitedDocs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                debugPrint('CLOUD FUNCTION: Message found with chat_id: ${data['chat_id']}, sender: ${data['sender_id']}');
                return Message.fromMap(data);
              }).toList();
            } else {
              debugPrint('CLOUD FUNCTION: No messages found for conversation $conversationId');
              // Let's check if there are ANY messages for this user
              _firestore
                  .collection(_universityPath)
                  .doc('data')
                  .collection('users')
                  .doc(userDocId)
                  .collection('messages')
                  .get()
                  .then((allMessagesSnapshot) {
                debugPrint('CLOUD FUNCTION: Total messages for user $userDocId: ${allMessagesSnapshot.docs.length}');
                for (var doc in allMessagesSnapshot.docs) {
                  final data = doc.data();
                  debugPrint('CLOUD FUNCTION: Found message with chat_id: ${data['chat_id']}');
                }
              });
            }
            
            // Update cache
            _messagesCache[conversationId] = messages;
            
            // Share data with other tabs
            if (kIsWeb && _tabVisibilityManager.isLeader) {
              _tabVisibilityManager.shareData('messaging_service', {
                'type': 'messages_update',
                'conversationId': conversationId,
                'messages': messages.map((m) => m.toMap()).toList(),
              });
            }
            
            controller.add(messages);
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading messages: $error');
            // If it's an index error, just return empty messages
            if (error.toString().contains('index') || error.toString().contains('Index')) {
              debugPrint('Index not ready, returning empty messages');
              controller.add([]);
            } else {
              _error = 'Failed to load messages';
              controller.addError(error);
            }
            notifyListeners();
          },
        );
      } catch (e) {
        debugPrint('Error setting up message listener: $e');
        controller.add([]);
        notifyListeners();
      }
    }).catchError((error) {
      debugPrint('Error getting user document: $error');
      controller.addError(error);
    });
    
    return controller.stream;
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    debugPrint('=== MESSAGING SERVICE SEND MESSAGE DEBUG ===');
    debugPrint('conversationId: $conversationId');
    debugPrint('senderId: $senderId');
    debugPrint('message: "$message"');
    
    try {
      final messageDoc = {
        'chat_id': conversationId,
        'sender_id': senderId,
        'message': message.trim(),
        'sent_at': FieldValue.serverTimestamp(),
        'synced': true,
      };
      
      debugPrint('Created message document: ${messageDoc.toString()}');
      
      // Extract recipient ID from conversation ID
      final parts = conversationId.split('__');
      if (parts.length != 2) {
        debugPrint('ERROR: Invalid conversation ID format: $conversationId');
        return false;
      }
      
      final recipientId = parts[0] == senderId ? parts[1] : parts[0];
      
      debugPrint('Extracted recipientId: $recipientId');
      debugPrint('Sending message from $senderId to $recipientId in conversation $conversationId');
      
      // Save to both users' subcollections using a batch write
      final batch = _firestore.batch();
      
      // 1. Save to sender's messages subcollection
      final senderPath = '/$_universityPath/data/users/$senderId/messages';
      debugPrint('CLOUD FUNCTION: Sender path: $senderPath');
      debugPrint('CLOUD FUNCTION: University path from CloudFunctionService: $_universityPath');
      
      final senderMessageRef = _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .doc(senderId)
          .collection('messages')
          .doc(); // Auto-generate ID
      
      debugPrint('Adding to batch: sender message with ID: ${senderMessageRef.id}');
      batch.set(senderMessageRef, messageDoc);
      
      // 2. Save to recipient's messages subcollection
      final recipientPath = '/$_universityPath/data/users/$recipientId/messages';
      debugPrint('Recipient path: $recipientPath');
      
      final recipientMessageRef = _firestore
          .collection(_universityPath)
          .doc('data')
          .collection('users')
          .doc(recipientId)
          .collection('messages')
          .doc(); // Auto-generate ID
      
      debugPrint('Adding to batch: recipient message with ID: ${recipientMessageRef.id}');
      batch.set(recipientMessageRef, messageDoc);
      
      // Commit the batch
      debugPrint('Committing batch write...');
      final startTime = DateTime.now();
      await batch.commit();
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      debugPrint('Batch commit successful in ${duration}ms');
      debugPrint('Message sent successfully to both users subcollections');
      debugPrint('=== END MESSAGING SERVICE SEND MESSAGE DEBUG ===');
      return true;
    } catch (e, stackTrace) {
      debugPrint('ERROR sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Listen to typing indicators
  Stream<TypingIndicator?> getTypingIndicatorStream(String conversationId, String userId) {
    final controller = StreamController<TypingIndicator?>.broadcast();
    
    // Cancel existing subscription
    _typingSubscriptions[conversationId]?.cancel();
    
    // Create a document path for typing indicators
    final typingDoc = _firestore
        .collection(_universityPath)
        .doc('data')
        .collection('typing_indicators')
        .doc(conversationId);
    
    _typingSubscriptions[conversationId] = typingDoc.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          controller.add(null);
          return;
        }
        
        final data = snapshot.data()!;
        final typingUsers = Map<String, dynamic>.from(data['users'] ?? {});
        
        // Remove current user and expired indicators
        final now = DateTime.now();
        typingUsers.removeWhere((uid, timestamp) {
          if (uid == userId) return true;
          final typingTime = (timestamp as Timestamp).toDate();
          return now.difference(typingTime).inSeconds > 5;
        });
        
        if (typingUsers.isEmpty) {
          controller.add(null);
        } else {
          // Get user details for typing users
          final userNames = <String>[];
          for (var uid in typingUsers.keys) {
            final user = _userService.getUserById(uid);
            if (user != null) {
              userNames.add(user.name.split(' ').first);
            }
          }
          
          if (userNames.isNotEmpty) {
            controller.add(TypingIndicator(
              conversationId: conversationId,
              userIds: typingUsers.keys.toList(),
              userNames: userNames,
            ));
          } else {
            controller.add(null);
          }
        }
      },
      onError: (error) {
        debugPrint('Error loading typing indicator: $error');
        controller.addError(error);
      },
    );
    
    return controller.stream;
  }

  /// Update typing indicator
  Future<void> updateTypingIndicator(String conversationId, String userId, bool isTyping) async {
    try {
      final typingDoc = _firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('typing_indicators')
          .doc(conversationId);
      
      if (isTyping) {
        await typingDoc.set({
          'users': {
            userId: FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      } else {
        await typingDoc.update({
          'users.$userId': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint('Error updating typing indicator: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // TODO: Implement read receipts
      // This would update a read_status collection or field
      debugPrint('Marking messages as read for $conversationId by $userId');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Helper methods
  String _generateChatId(String mentorId, String menteeId) {
    // Always put mentor ID first for consistency
    return '${mentorId}__${menteeId}';
  }
  
  /// Static helper to generate chat ID
  static String generateChatId(String userId1, String userId2) {
    // Always put IDs in consistent order (alphabetically)
    // This ensures the same chat ID regardless of who initiates
    debugPrint('Generating chat ID for: $userId1 and $userId2');
    String chatId;
    if (userId1.compareTo(userId2) < 0) {
      chatId = '${userId1}__${userId2}';
    } else {
      chatId = '${userId2}__${userId1}';
    }
    debugPrint('Generated chat ID: $chatId');
    return chatId;
  }

  Future<Message?> _getLastMessage(String chatId) async {
    try {
      // Extract user IDs from chat ID to query their subcollections
      final parts = chatId.split('__');
      if (parts.length != 2) return null;
      
      final mentorId = parts[0];
      final menteeId = parts[1];
      
      // Try to get the last message from mentor's subcollection first
      var snapshot = await _firestore
          .collection('california_merced_uc_merced')
          .doc('data')
          .collection('users')
          .doc(mentorId)
          .collection('messages')
          .where('chat_id', isEqualTo: chatId)
          .get();
      
      // If not found in mentor's collection, try mentee's collection
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('california_merced_uc_merced')
            .doc('data')
            .collection('users')
            .doc(menteeId)
            .collection('messages')
            .where('chat_id', isEqualTo: chatId)
            .get();
      }
      
      // Sort in memory to avoid index issues
      if (snapshot.docs.isNotEmpty) {
        final sortedDocs = List.from(snapshot.docs);
        sortedDocs.sort((a, b) {
          final aTime = a.data()['sent_at'] as Timestamp?;
          final bTime = b.data()['sent_at'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });
        
        // Get the most recent message
        final latestDoc = sortedDocs.first;
        final data = latestDoc.data();
        data['id'] = latestDoc.id;
        return Message.fromMap(data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  void _handleMessagesUpdate(String conversationId, List<dynamic> messages) {
    _messagesCache[conversationId] = messages.map((m) => Message.fromMap(m)).toList();
    notifyListeners();
  }

  void _handleConversationsUpdate(List<dynamic> conversations) {
    for (var conv in conversations) {
      final conversation = Conversation.fromMap(conv);
      _conversationsCache[conversation.id] = conversation;
    }
    notifyListeners();
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