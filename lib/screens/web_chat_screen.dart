import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class WebChatScreen extends StatefulWidget {
  final String recipientName;
  final String recipientRole;

  const WebChatScreen({
    super.key,
    required this.recipientName,
    required this.recipientRole,
  });

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mock messages for demonstration
  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'You',
      'message': 'Hi! I wanted to discuss my progress on the current assignment.',
      'time': '10:30 AM',
      'isMe': true,
    },
    {
      'sender': 'Sarah Martinez',
      'message': 'Hello! I\'d be happy to discuss that. How are things going?',
      'time': '10:32 AM',
      'isMe': false,
    },
    {
      'sender': 'You',
      'message': 'I\'m making good progress but have a few questions about the requirements.',
      'time': '10:33 AM',
      'isMe': true,
    },
    {
      'sender': 'Sarah Martinez',
      'message': 'Sure, what questions do you have? I\'m here to help!',
      'time': '10:35 AM',
      'isMe': false,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        'sender': 'You',
        'message': _messageController.text.trim(),
        'time': TimeOfDay.now().format(context),
        'isMe': true,
      });
    });

    _messageController.clear();

    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Conversation list sidebar (desktop/tablet only)
          if (isDesktop || isTablet)
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    // Conversation list
                    Expanded(
                      child: ListView(
                        children: [
                          _buildConversationItem(
                            widget.recipientName,
                            widget.recipientRole,
                            'I\'m here to help!',
                            '10:35 AM',
                            true,
                            true,
                          ),
                          _buildConversationItem(
                            'Clarissa Correa',
                            'Program Coordinator',
                            'Please review the updated guidelines',
                            'Yesterday',
                            false,
                            false,
                          ),
                          _buildConversationItem(
                            'John Davis',
                            '4th Year, Biology Major',
                            'Thanks for the resources!',
                            '2 days ago',
                            false,
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Main chat area
          Expanded(
            child: Column(
              children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop && !isTablet)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0F2D52),
                        child: Text(
                          widget.recipientName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.recipientRole,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      IconButton(
                        icon: const Icon(Icons.videocam_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video call feature coming soon!')),
                          );
                        },
                        tooltip: 'Start video call',
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice call feature coming soon!')),
                          );
                        },
                        tooltip: 'Start voice call',
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'clear':
                              _showClearChatDialog();
                              break;
                            case 'block':
                              _showBlockUserDialog();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'clear',
                            child: Text('Clear chat'),
                          ),
                          const PopupMenuItem(
                            value: 'block',
                            child: Text('Block user'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Messages area
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessage(
                          message['message'],
                          message['time'],
                          message['isMe'],
                        );
                      },
                    ),
                  ),
                ),
                
                // Message input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {
                          // TODO: Implement file attachment
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File attachment coming soon!')),
                          );
                        },
                        tooltip: 'Attach file',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                        color: const Color(0xFF0F2D52),
                        tooltip: 'Send message',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
    String name,
    String role,
    String lastMessage,
    String time,
    bool isActive,
    bool hasUnread,
  ) {
    return ListTile(
      selected: isActive,
      selectedTileColor: Colors.grey[200],
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0F2D52),
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? Colors.black87 : Colors.grey[600],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? const Color(0xFF0F2D52) : Colors.grey[600],
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F2D52),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Switch conversation
      },
    );
  }

  Widget _buildMessage(String message, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0F2D52) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                messages.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.recipientName}? You will no longer receive messages from this user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.recipientName} has been blocked')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}