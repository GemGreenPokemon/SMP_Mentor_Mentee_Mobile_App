import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart' as models;
import '../models/user.dart';
import '../services/messaging_service.dart';
import '../services/local_database_service.dart';
import '../utils/test_mode_manager.dart';

class ChatScreen extends StatefulWidget {
  final String recipientName;
  final String recipientRole;
  final String? currentUserId;  // Optional: explicitly pass current user
  final String? recipientId;     // Optional: explicitly pass recipient ID

  const ChatScreen({
    super.key,
    required this.recipientName,
    required this.recipientRole,
    this.currentUserId,
    this.recipientId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagingService _messagingService = MessagingService.instance;
  final _localDb = LocalDatabaseService.instance;
  
  List<models.Message> _messages = [];
  User? _currentUser;
  User? _recipientUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Listen to messaging service changes
    _messagingService.addListener(_onMessagingUpdate);
  }
  
  @override
  void dispose() {
    _messagingService.removeListener(_onMessagingUpdate);
    _messageController.dispose();
    super.dispose();
  }
  
  void _onMessagingUpdate() {
    debugPrint('ChatScreen._onMessagingUpdate: Service notified of changes');
    // Reload messages when service notifies of changes
    _loadMessages();
  }
  
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    debugPrint('ChatScreen._initializeChat: Starting initialization');
    debugPrint('  Widget parameters:');
    debugPrint('    recipientName: ${widget.recipientName}');
    debugPrint('    recipientRole: ${widget.recipientRole}');
    debugPrint('    currentUserId: ${widget.currentUserId}');
    debugPrint('    recipientId: ${widget.recipientId}');
    debugPrint('  Test mode status:');
    debugPrint('    isTestMode: ${TestModeManager.isTestMode}');
    debugPrint('    hasCompleteTestData: ${TestModeManager.hasCompleteTestData}');
    
    try {
      // Initialize messaging service
      await _messagingService.initialize();
      
      // Determine current user based on context
      if (TestModeManager.isTestMode && TestModeManager.hasCompleteTestData) {
        debugPrint('  Test users available:');
        debugPrint('    Mentor: ${TestModeManager.currentTestMentor?.name} (${TestModeManager.currentTestMentor?.id})');
        debugPrint('    Mentee: ${TestModeManager.currentTestMentee?.name} (${TestModeManager.currentTestMentee?.id})');
        
        // Use explicit IDs if provided
        if (widget.currentUserId != null && widget.recipientId != null) {
          debugPrint('  Using explicit IDs from widget');
          // Find users by ID matching
          if (widget.currentUserId == TestModeManager.currentTestMentor?.id) {
            _currentUser = TestModeManager.currentTestMentor;
            // Verify recipient ID matches mentee
            if (widget.recipientId == TestModeManager.currentTestMentee?.id) {
              _recipientUser = TestModeManager.currentTestMentee;
            } else {
              debugPrint('  WARNING: Recipient ID does not match test mentee!');
            }
          } else if (widget.currentUserId == TestModeManager.currentTestMentee?.id) {
            _currentUser = TestModeManager.currentTestMentee;
            // Verify recipient ID matches mentor
            if (widget.recipientId == TestModeManager.currentTestMentor?.id) {
              _recipientUser = TestModeManager.currentTestMentor;
            } else {
              debugPrint('  WARNING: Recipient ID does not match test mentor!');
            }
          } else {
            debugPrint('  WARNING: Current user ID does not match any test user!');
          }
        } else {
          debugPrint('  Falling back to name matching (IDs not provided)');
          // Fallback to name matching
          if (widget.recipientName == TestModeManager.currentTestMentor?.name) {
            _currentUser = TestModeManager.currentTestMentee;
            _recipientUser = TestModeManager.currentTestMentor;
          } else {
            _currentUser = TestModeManager.currentTestMentor;
            _recipientUser = TestModeManager.currentTestMentee;
          }
        }
        
        debugPrint('ChatScreen initialized:');
        debugPrint('  Current user: ${_currentUser?.name} (${_currentUser?.id})');
        debugPrint('  Recipient: ${_recipientUser?.name} (${_recipientUser?.id})');
      } else {
        debugPrint('  Not in test mode or incomplete test data');
      }
      
      // Load messages
      _loadMessages();
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _loadMessages() async {
    if (_currentUser != null && _recipientUser != null) {
      debugPrint('ChatScreen._loadMessages:');
      debugPrint('  Loading messages between ${_currentUser!.name} and ${_recipientUser!.name}');
      debugPrint('  Current user ID: ${_currentUser!.id}');
      
      final messages = await _messagingService.getMessagesForUser(
        _currentUser!.id, 
        _recipientUser!.id,
        _currentUser!.id // Pass current user ID for visibility check
      );
      
      debugPrint('  Loaded ${messages.length} visible messages');
      debugPrint('  _messages before setState: ${_messages.length}');
      
      setState(() {
        _messages = messages;
      });
      
      debugPrint('  _messages after setState: ${_messages.length}');
      
      // Force a rebuild if needed
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } else {
      debugPrint('ChatScreen._loadMessages: Current user or recipient is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName),
            Text(
              widget.recipientRole,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Chat Debug Info'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Current User: ${_currentUser?.name} (${_currentUser?.id})'),
                        Text('Recipient: ${_recipientUser?.name} (${_recipientUser?.id})'),
                        Text('Messages in memory: ${_messages.length}'),
                        Text('Service message count: ${_messagingService.getMessageCount()}'),
                        const SizedBox(height: 10),
                        Text('Chat ID: ${_currentUser != null && _recipientUser != null ? _messagingService.generateChatId(_currentUser!.id, _recipientUser!.id) : "N/A"}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadMessages();
                      },
                      child: const Text('Reload Messages'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat History'),
                    content: const Text('This will clear the chat history for you only. The other person will still see all messages. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && _currentUser != null) {
                  await _messagingService.clearMessagesForCurrentUser(_currentUser!.id);
                  _loadMessages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat history cleared for you'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat (For Me)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          TestModeManager.isTestMode
                              ? 'No messages yet. Start the conversation!'
                              : 'Messages are only available in test mode',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadMessages,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Messages'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Debug: ${_messages.length} messages in memory',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Implement file attachment
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(models.Message message) {
    final isSentByMe = _currentUser != null && message.senderId == _currentUser!.id;
    final time = _formatTime(message.sentAt);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _recipientUser?.name.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSentByMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _currentUser?.name.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _sendMessage() async {
    debugPrint('ChatScreen._sendMessage: Starting send process');
    debugPrint('  Message text: "${_messageController.text.trim()}"');
    debugPrint('  Current user: ${_currentUser?.name} (${_currentUser?.id}) - ${_currentUser != null ? "exists" : "NULL"}');
    debugPrint('  Recipient user: ${_recipientUser?.name} (${_recipientUser?.id}) - ${_recipientUser != null ? "exists" : "NULL"}');
    
    if (_messageController.text.trim().isNotEmpty && 
        _currentUser != null && 
        _recipientUser != null) {
      
      final messageText = _messageController.text.trim();
      _messageController.clear();
      
      debugPrint('ChatScreen._sendMessage: All conditions met, sending...');
      debugPrint('  From: ${_currentUser!.name} (${_currentUser!.id})');
      debugPrint('  To: ${_recipientUser!.name} (${_recipientUser!.id})');
      debugPrint('  Message: $messageText');
      
      // Generate expected chat ID for debugging
      final expectedChatId = _messagingService.generateChatId(_currentUser!.id, _recipientUser!.id);
      debugPrint('  Expected Chat ID: $expectedChatId');
      
      // Send message through service
      final success = await _messagingService.sendMessage(
        senderId: _currentUser!.id,
        recipientId: _recipientUser!.id,
        messageText: messageText,
      );
      
      if (success) {
        debugPrint('  Message sent successfully, reloading messages...');
        // Reload messages to show the new one
        _loadMessages();
      } else {
        debugPrint('  Failed to send message');
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      debugPrint('ChatScreen._sendMessage: Cannot send - conditions not met');
      debugPrint('  Empty message: ${_messageController.text.trim().isEmpty}');
      debugPrint('  Current user null: ${_currentUser == null}');
      debugPrint('  Recipient user null: ${_recipientUser == null}');
    }
  }

} 