import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../models/message.dart';
import '../../../../../models/user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/real_time_user_service.dart';
import '../../../../../services/tab_visibility_manager/tab_visibility_manager.dart';
import '../models/conversation.dart';
import '../models/typing_indicator.dart';
import '../models/message_status.dart';

class MessagingService extends ChangeNotifier {
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final RealTimeUserService _userService = RealTimeUserService();
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
  
  // University path - hardcoded for now, should be dynamic in production
  final String _universityPath = 'California/Merced/UC_Merced';
  
  // Helper method to get Firestore base path
  DocumentReference get _universityDoc {
    final parts = _universityPath.split('/');
    return _firestore
        .collection('universities')
        .doc(parts[0])  // California
        .collection(parts[1])  // Merced
        .doc(parts[2]); // UC_Merced
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
    
    // Query based on user type - get from current user's data
    String userType = 'mentor'; // default
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      final currentUserData = _userService.getUserById(currentUserId);
      if (currentUserData != null) {
        userType = currentUserData.userType;
      }
    }
    
    Query query;
    
    if (userType == 'mentor') {
      // For mentors, get conversations where they are the mentor
      query = _universityDoc
          .collection('data')
          .doc('data')
          .collection('mentorships')
          .where('mentor_id', isEqualTo: userId);
    } else {
      // For mentees, get conversations where they are the mentee
      query = _universityDoc
          .collection('data')
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
          
          // Get user details
          final otherUser = _userService.getUserById(otherUserId);
          if (otherUser == null) continue;
          
          // Get last message
          final chatId = _generateChatId(mentorId, menteeId);
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
    
    // Listen to messages
    _messageSubscriptions[conversationId] = _universityDoc
        .collection('data')
        .doc('data')
        .collection('messages')
        .where('chat_id', isEqualTo: conversationId)
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .snapshots()
        .listen(
      (snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Message.fromMap(data);
        }).toList();
        
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
        _error = 'Failed to load messages';
        controller.addError(error);
        notifyListeners();
      },
    );
    
    return controller.stream;
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    try {
      final messageDoc = {
        'chat_id': conversationId,
        'sender_id': senderId,
        'message': message.trim(),
        'sent_at': FieldValue.serverTimestamp(),
        'synced': true,
      };
      
      await _universityDoc
          .collection('data')
          .doc('data')
          .collection('messages')
          .add(messageDoc);
      
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      _error = 'Failed to send message';
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
    final typingDoc = _universityDoc
        .collection('data')
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
      final typingDoc = _universityDoc
          .collection('data')
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

  Future<Message?> _getLastMessage(String chatId) async {
    try {
      final snapshot = await _universityDoc
          .collection('data')
          .doc('data')
          .collection('messages')
          .where('chat_id', isEqualTo: chatId)
          .orderBy('sent_at', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Message.fromMap(data);
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