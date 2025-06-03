import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/messaging_service.dart';
import '../services/local_database_service.dart';
import '../utils/test_mode_manager.dart';

class MessagingDebugScreen extends StatefulWidget {
  const MessagingDebugScreen({Key? key}) : super(key: key);

  @override
  State<MessagingDebugScreen> createState() => _MessagingDebugScreenState();
}

class _MessagingDebugScreenState extends State<MessagingDebugScreen> {
  final _messagingService = MessagingService.instance;
  final _localDb = LocalDatabaseService.instance;
  
  List<Map<String, dynamic>> _debugInfo = [];
  List<Map<String, dynamic>> _messagesInDb = [];
  String _fullDebugLog = '';
  
  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }
  
  Future<void> _loadDebugInfo() async {
    final info = <Map<String, dynamic>>[];
    final debugLog = StringBuffer();
    
    // Header
    debugLog.writeln('=== MESSAGING DEBUG LOG ===');
    debugLog.writeln('Generated: ${DateTime.now()}');
    debugLog.writeln('');
    
    // Test mode status
    debugLog.writeln('TEST MODE STATUS:');
    info.add({
      'category': 'Test Mode',
      'key': 'Enabled',
      'value': TestModeManager.isTestMode.toString(),
    });
    debugLog.writeln('  Enabled: ${TestModeManager.isTestMode}');
    
    info.add({
      'category': 'Test Mode',
      'key': 'Has Complete Data',
      'value': TestModeManager.hasCompleteTestData.toString(),
    });
    debugLog.writeln('  Has Complete Data: ${TestModeManager.hasCompleteTestData}');
    debugLog.writeln('');
    
    // Current users
    debugLog.writeln('CURRENT USERS:');
    if (TestModeManager.currentTestMentor != null) {
      final mentor = TestModeManager.currentTestMentor!;
      info.add({
        'category': 'Current Users',
        'key': 'Mentor',
        'value': '${mentor.name} (${mentor.id})',
      });
      debugLog.writeln('  Mentor:');
      debugLog.writeln('    Name: ${mentor.name}');
      debugLog.writeln('    ID: ${mentor.id}');
      debugLog.writeln('    Email: ${mentor.email}');
      debugLog.writeln('    Type: ${mentor.userType}');
    } else {
      debugLog.writeln('  Mentor: NULL');
    }
    
    if (TestModeManager.currentTestMentee != null) {
      final mentee = TestModeManager.currentTestMentee!;
      info.add({
        'category': 'Current Users',
        'key': 'Mentee', 
        'value': '${mentee.name} (${mentee.id})',
      });
      debugLog.writeln('  Mentee:');
      debugLog.writeln('    Name: ${mentee.name}');
      debugLog.writeln('    ID: ${mentee.id}');
      debugLog.writeln('    Email: ${mentee.email}');
      debugLog.writeln('    Type: ${mentee.userType}');
    } else {
      debugLog.writeln('  Mentee: NULL');
    }
    debugLog.writeln('');
    
    // Messaging configuration
    debugLog.writeln('MESSAGING CONFIGURATION:');
    if (TestModeManager.hasCompleteTestData) {
      final mentorId = TestModeManager.currentTestMentor!.id;
      final menteeId = TestModeManager.currentTestMentee!.id;
      final chatId = '${mentorId}__${menteeId}';
      
      info.add({
        'category': 'Messaging',
        'key': 'Chat ID',
        'value': chatId,
      });
      debugLog.writeln('  Chat ID: $chatId');
      debugLog.writeln('  Chat ID Format: mentorId__menteeId');
      debugLog.writeln('  Mentor ID: $mentorId');
      debugLog.writeln('  Mentee ID: $menteeId');
      
      // Database query
      debugLog.writeln('');
      debugLog.writeln('DATABASE QUERY:');
      debugLog.writeln('  Table: messages');
      debugLog.writeln('  Where: chat_id = "$chatId"');
      
      // Messages count
      final messages = await _localDb.getMessagesByChat(chatId);
      info.add({
        'category': 'Messaging',
        'key': 'Messages in DB',
        'value': messages.length.toString(),
      });
      debugLog.writeln('  Result Count: ${messages.length}');
      
      // Load messages
      _messagesInDb = messages.map((msg) => {
        'id': msg.id,
        'chatId': msg.chatId,
        'sender': msg.senderId,
        'message': msg.message,
        'time': DateTime.fromMillisecondsSinceEpoch(msg.sentAt.millisecondsSinceEpoch).toString(),
        'synced': msg.synced,
      }).toList();
      
      // Messages detail
      debugLog.writeln('');
      debugLog.writeln('MESSAGES DETAIL:');
      if (_messagesInDb.isEmpty) {
        debugLog.writeln('  No messages found');
      } else {
        for (var i = 0; i < _messagesInDb.length; i++) {
          final msg = _messagesInDb[i];
          debugLog.writeln('  Message ${i + 1}:');
          debugLog.writeln('    ID: ${msg['id']}');
          debugLog.writeln('    Chat ID: ${msg['chatId']}');
          debugLog.writeln('    Sender ID: ${msg['sender']}');
          debugLog.writeln('    Message: ${msg['message']}');
          debugLog.writeln('    Time: ${msg['time']}');
          debugLog.writeln('    Synced: ${msg['synced']}');
          debugLog.writeln('');
        }
      }
    } else {
      debugLog.writeln('  Cannot generate chat ID - incomplete test data');
    }
    
    // Service state
    debugLog.writeln('SERVICE STATE:');
    info.add({
      'category': 'Service State',
      'key': 'Message Count',
      'value': _messagingService.getMessageCount().toString(),
    });
    info.add({
      'category': 'Service State',
      'key': 'Is Loading',
      'value': _messagingService.isLoading.toString(),
    });
    debugLog.writeln('  Message Count: ${_messagingService.getMessageCount()}');
    debugLog.writeln('  Is Loading: ${_messagingService.isLoading}');
    
    // Test send parameters
    debugLog.writeln('');
    debugLog.writeln('TEST SEND PARAMETERS:');
    if (TestModeManager.hasCompleteTestData) {
      debugLog.writeln('  As Mentor:');
      debugLog.writeln('    Sender ID: ${TestModeManager.currentTestMentor!.id}');
      debugLog.writeln('    Recipient ID: ${TestModeManager.currentTestMentee!.id}');
      debugLog.writeln('  As Mentee:');
      debugLog.writeln('    Sender ID: ${TestModeManager.currentTestMentee!.id}');
      debugLog.writeln('    Recipient ID: ${TestModeManager.currentTestMentor!.id}');
      debugLog.writeln('  Message Format: "Test message from [role] at [timestamp]"');
    } else {
      debugLog.writeln('  Cannot send - incomplete test data');
    }
    
    // Chat screen parameters
    debugLog.writeln('');
    debugLog.writeln('CHAT SCREEN EXPECTED PARAMETERS:');
    if (TestModeManager.hasCompleteTestData) {
      debugLog.writeln('  From Mentor Dashboard:');
      debugLog.writeln('    recipientName: ${TestModeManager.currentTestMentee!.name}');
      debugLog.writeln('    recipientRole: [mentee program/year]');
      debugLog.writeln('    currentUserId: ${TestModeManager.currentTestMentor!.id}');
      debugLog.writeln('    recipientId: ${TestModeManager.currentTestMentee!.id}');
      debugLog.writeln('  From Mentee Dashboard:');
      debugLog.writeln('    recipientName: ${TestModeManager.currentTestMentor!.name}');
      debugLog.writeln('    recipientRole: [mentor role]');
      debugLog.writeln('    currentUserId: ${TestModeManager.currentTestMentee!.id}');
      debugLog.writeln('    recipientId: ${TestModeManager.currentTestMentor!.id}');
    }
    
    // Message routing logic
    debugLog.writeln('');
    debugLog.writeln('MESSAGE ROUTING LOGIC:');
    debugLog.writeln('  1. ChatScreen receives currentUserId and recipientId');
    debugLog.writeln('  2. MessagingService.sendMessage() called with:');
    debugLog.writeln('     - senderId: currentUserId');
    debugLog.writeln('     - recipientId: recipientId');
    debugLog.writeln('     - messageText: user input');
    debugLog.writeln('  3. Chat ID generated as: mentorId__menteeId');
    debugLog.writeln('  4. Message saved to local DB with chat_id');
    debugLog.writeln('  5. MessagingService notifies listeners');
    debugLog.writeln('  6. ChatScreen reloads messages via listener');
    
    setState(() {
      _debugInfo = info;
      _fullDebugLog = debugLog.toString();
    });
  }
  
  Future<void> _testSendMessage({bool asMentor = true}) async {
    if (!TestModeManager.hasCompleteTestData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test mode not properly configured')),
      );
      return;
    }
    
    final senderId = asMentor 
        ? TestModeManager.currentTestMentor!.id 
        : TestModeManager.currentTestMentee!.id;
    final recipientId = asMentor 
        ? TestModeManager.currentTestMentee!.id 
        : TestModeManager.currentTestMentor!.id;
    final senderName = asMentor ? 'Mentor' : 'Mentee';
    
    final success = await _messagingService.sendMessage(
      senderId: senderId,
      recipientId: recipientId,
      messageText: 'Test message from $senderName at ${DateTime.now()}',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success 
            ? 'Message sent successfully as $senderName' 
            : 'Failed to send message as $senderName'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    
    // Reload debug info
    await _loadDebugInfo();
  }
  
  Future<void> _clearMessages() async {
    await _messagingService.clearAllMessages();
    await _loadDebugInfo();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages cleared')),
    );
  }
  
  Future<void> _copyDebugLog() async {
    await Clipboard.setData(ClipboardData(text: _fullDebugLog));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug log copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyDebugLog,
            tooltip: 'Copy debug log',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug info table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._buildDebugTable(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _testSendMessage(asMentor: true),
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text('Send as Mentor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _testSendMessage(asMentor: false),
                          icon: const Icon(Icons.school, size: 18),
                          label: const Text('Send as Mentee'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _clearMessages,
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text('Clear Messages'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Messages in database
            if (_messagesInDb.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Messages in Database',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._messagesInDb.map((msg) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${msg['id']}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              'Chat ID: ${msg['chatId']}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              'From: ${msg['sender']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(msg['message']),
                            Text(
                              msg['time'],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Full debug log
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Full Debug Log',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: _copyDebugLog,
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _fullDebugLog,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildDebugTable() {
    final widgets = <Widget>[];
    String? currentCategory;
    
    for (final info in _debugInfo) {
      if (currentCategory != info['category']) {
        if (currentCategory != null) {
          widgets.add(const SizedBox(height: 16));
        }
        currentCategory = info['category'];
        widgets.add(
          Text(
            currentCategory!,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        );
        widgets.add(const Divider());
      }
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(info['key']),
              Expanded(
                child: Text(
                  info['value'],
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
}