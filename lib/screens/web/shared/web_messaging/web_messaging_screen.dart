import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/real_time_user_service.dart';
import '../../../../services/cloud_function_service.dart';
import '../../../../utils/responsive.dart';
import 'services/messaging_service.dart';
import 'controllers/conversation_controller.dart';
import 'controllers/message_controller.dart';
import 'widgets/conversation_list/conversation_list.dart';
import 'widgets/message_thread/message_thread.dart';
import 'utils/messaging_constants.dart';

class WebMessagingScreen extends StatefulWidget {
  final String? preSelectedUserId;
  final String? preSelectedUserName;
  
  const WebMessagingScreen({
    super.key,
    this.preSelectedUserId,
    this.preSelectedUserName,
  });

  @override
  State<WebMessagingScreen> createState() => _WebMessagingScreenState();
}

class _WebMessagingScreenState extends State<WebMessagingScreen> {
  late MessagingService _messagingService;
  late ConversationController _conversationController;
  late MessageController _messageController;
  final AuthService _authService = AuthService();
  final RealTimeUserService _userService = RealTimeUserService();
  final CloudFunctionService _cloudFunctions = CloudFunctionService();
  
  String? _selectedConversationId;
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserRole;
  String? _currentUserDocId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Get user type and document ID from Firestore (following dashboard pattern)
    String userType = 'mentor'; // default
    String userDocId = currentUser.uid; // fallback
    
    try {
      // Query to get user document by Firebase UID
      final firestore = FirebaseFirestore.instance;
      final universityPath = _cloudFunctions.getCurrentUniversityPath();
      final userSnapshot = await firestore
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .where('firebase_uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (userSnapshot.docs.isNotEmpty) {
        final userDoc = userSnapshot.docs.first;
        userDocId = userDoc.id; // e.g., "Emerald_Nash"
        final userData = userDoc.data();
        userType = userData['userType'] ?? userData['user_type'] ?? 'mentor';
        
        debugPrint('MessagingScreen: Found user document ID: $userDocId for Firebase UID: ${currentUser.uid}');
      } else {
        debugPrint('MessagingScreen: No user document found for Firebase UID: ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('MessagingScreen: Error getting user document: $e');
    }
    
    // Store the document ID for later use
    _currentUserDocId = userDocId;

    _messagingService = MessagingService();
    _conversationController = ConversationController(
      messagingService: _messagingService,
      userId: userDocId, // Use document ID instead of Firebase UID
      userType: userType,
    );
    _messageController = MessageController(
      messagingService: _messagingService,
      currentUserId: userDocId, // Use document ID instead of Firebase UID
    );

    // Initialize the services
    _messagingService.initialize();
    
    // Ensure RealTimeUserService is listening
    if (!_userService.connectionState.name.contains('connected')) {
      _userService.startListening(_cloudFunctions.getCurrentUniversityPath());
    }
    
    _conversationController.loadConversations();
    
    // If pre-selected user, wait for conversations to load then select it
    if (widget.preSelectedUserId != null && widget.preSelectedUserName != null) {
      // Ensure we have the document ID before proceeding
      if (userDocId != currentUser.uid) {
        debugPrint('MessagingScreen: Document ID loaded successfully, proceeding with pre-selection');
        _selectPreSelectedConversation(userDocId);
      } else {
        debugPrint('MessagingScreen: WARNING - Using Firebase UID as fallback, this may cause issues');
        _selectPreSelectedConversation(userDocId);
      }
    }
  }
  
  void _selectPreSelectedConversation(String currentUserDocId) {
    // Store the doc ID first
    _currentUserDocId = currentUserDocId;
    
    debugPrint('MessagingScreen: Pre-selected user info:');
    debugPrint('  - preSelectedUserId: ${widget.preSelectedUserId}');
    debugPrint('  - preSelectedUserName: ${widget.preSelectedUserName}');
    debugPrint('  - currentUserDocId: $currentUserDocId');
    
    // Wait a bit for conversations to load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // Generate the conversation ID
      final conversationId = MessagingService.generateChatId(
        currentUserDocId,
        widget.preSelectedUserId!
      );
      
      debugPrint('MessagingScreen: Generated conversation ID: $conversationId');
      debugPrint('  - Should be format: ${currentUserDocId}__${widget.preSelectedUserId}');
      
      // Select the conversation
      _onConversationSelected(
        conversationId,
        widget.preSelectedUserId!,
        widget.preSelectedUserName!,
        'mentee', // Assuming pre-selected is always a mentee when coming from dashboard
      );
    });
  }

  @override
  void dispose() {
    _messagingService.dispose();
    _conversationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onConversationSelected(String conversationId, String userId, String userName, String userRole) {
    setState(() {
      _selectedConversationId = conversationId;
      _selectedUserId = userId;
      _selectedUserName = userName;
      _selectedUserRole = userRole;
    });
    
    // Load messages for selected conversation
    if (_currentUserDocId != null) {
      _messageController.loadMessages(conversationId, _currentUserDocId!, userId);
    } else {
      debugPrint('MessagingScreen: Cannot load messages - currentUserDocId is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final showSidebar = isDesktop || (isTablet && _selectedConversationId == null);

    return Scaffold(
      backgroundColor: MessagingConstants.backgroundColor,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _messagingService),
          ChangeNotifierProvider.value(value: _conversationController),
          ChangeNotifierProvider.value(value: _messageController),
        ],
        child: Row(
          children: [
            // Conversation list sidebar
            if (showSidebar)
              Container(
                width: isDesktop ? MessagingConstants.sidebarWidth : double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ConversationList(
                  onConversationSelected: _onConversationSelected,
                  selectedConversationId: _selectedConversationId,
                ),
              ),
            
            // Message thread area
            Expanded(
              child: _selectedConversationId == null
                  ? _buildEmptyState()
                  : MessageThread(
                      conversationId: _selectedConversationId!,
                      recipientId: _selectedUserId!,
                      recipientName: _selectedUserName!,
                      recipientRole: _selectedUserRole!,
                      onBack: isTablet
                          ? () {
                              setState(() {
                                _selectedConversationId = null;
                                _selectedUserId = null;
                                _selectedUserName = null;
                                _selectedUserRole = null;
                              });
                            }
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: MessagingConstants.messagesBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a conversation to start messaging',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a contact from the list to begin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}