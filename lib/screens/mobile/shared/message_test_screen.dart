import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageTestScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const MessageTestScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  State<MessageTestScreen> createState() => _MessageTestScreenState();
}

class _MessageTestScreenState extends State<MessageTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  String _currentUserId = 'testMentor123'; // Hardcoded for testing
  String _chatId = '';
  int _testCount = 0;

  @override
  void initState() {
    super.initState();
    _chatId = 'test_chat_${_currentUserId}_${widget.recipientId}';
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      setState(() {
        _messages = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error loading messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _sending = true;
    });

    try {
      // Create a message document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'receiverId': widget.recipientId,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat metadata
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'participants': [_currentUserId, widget.recipientId],
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messageController.clear();
      _loadMessages();
      
      setState(() {
        _testCount++;
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messaging Test: ${widget.recipientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('Chat ID: $_chatId'),
                    Text('Recipient ID: ${widget.recipientId}'),
                    Text('Your ID: $_currentUserId (test mentor)'),
                    Text('Messages sent this session: $_testCount'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                          size: 60, 
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send a test message below',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == _currentUserId;

                      return Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe ? 'You (Test Mentor)' : widget.recipientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message['text']),
                                const SizedBox(height: 4),
                                Text(
                                  message['timestamp'] != null
                                      ? '${(message['timestamp'] as Timestamp).toDate().hour}:${(message['timestamp'] as Timestamp).toDate().minute}'
                                      : 'Sending...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type test message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: _sending ? null : _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}