import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/real_time_user_service.dart';
import '../../../../utils/responsive.dart';
import 'services/messaging_service.dart';
import 'controllers/conversation_controller.dart';
import 'controllers/message_controller.dart';
import 'widgets/conversation_list/conversation_list.dart';
import 'widgets/message_thread/message_thread.dart';
import 'utils/messaging_constants.dart';

class WebMessagingScreen extends StatefulWidget {
  const WebMessagingScreen({super.key});

  @override
  State<WebMessagingScreen> createState() => _WebMessagingScreenState();
}

class _WebMessagingScreenState extends State<WebMessagingScreen> {
  late MessagingService _messagingService;
  late ConversationController _conversationController;
  late MessageController _messageController;
  final AuthService _authService = AuthService();
  final RealTimeUserService _userService = RealTimeUserService();
  
  String? _selectedConversationId;
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserRole;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Get user type from user service
    String userType = 'mentor'; // default
    final userData = _userService.getUserById(currentUser.uid);
    if (userData != null) {
      userType = userData.userType;
    }

    _messagingService = MessagingService();
    _conversationController = ConversationController(
      messagingService: _messagingService,
      userId: currentUser.uid,
      userType: userType,
    );
    _messageController = MessageController(
      messagingService: _messagingService,
      currentUserId: currentUser.uid,
    );

    // Initialize the services
    _messagingService.initialize();
    _conversationController.loadConversations();
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
    _messageController.loadMessages(conversationId, _authService.currentUser!.uid, userId);
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