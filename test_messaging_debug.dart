import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/services/cloud_function_service.dart';
import 'lib/services/conversation_service.dart';
import 'lib/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final authService = AuthService();
  final cloudFunctions = CloudFunctionService();
  final conversationService = ConversationService.instance;
  
  print('=== MESSAGING DEBUG TEST ===');
  
  try {
    // 1. Check current user
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      print('ERROR: No authenticated user');
      return;
    }
    print('✓ Authenticated user: ${currentUser.uid}');
    
    // 2. Get university path
    final universityPath = cloudFunctions.getCurrentUniversityPath();
    print('✓ University path: $universityPath');
    
    // 3. Get current user's document ID
    final userQuery = await FirebaseFirestore.instance
        .collection(universityPath)
        .doc('data')
        .collection('users')
        .where('firebase_uid', isEqualTo: currentUser.uid)
        .limit(1)
        .get();
    
    if (userQuery.docs.isEmpty) {
      print('ERROR: User document not found');
      return;
    }
    
    final currentUserDocId = userQuery.docs.first.id;
    print('✓ Current user doc ID: $currentUserDocId');
    
    // 4. Check if any conversations exist
    final conversationsQuery = await FirebaseFirestore.instance
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .where('participants', arrayContains: currentUserDocId)
        .limit(1)
        .get();
    
    if (conversationsQuery.docs.isEmpty) {
      print('WARNING: No conversations found for user');
      
      // Try to create a test conversation
      print('\\nAttempting to create a test conversation...');
      
      // Find another user to chat with
      final otherUsersQuery = await FirebaseFirestore.instance
          .collection(universityPath)
          .doc('data')
          .collection('users')
          .where('firebase_uid', isNotEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (otherUsersQuery.docs.isEmpty) {
        print('ERROR: No other users found to create conversation with');
        return;
      }
      
      final otherUserDocId = otherUsersQuery.docs.first.id;
      print('Found other user: $otherUserDocId');
      
      // Create conversation
      final conversationId = await conversationService.createConversation(
        user1Id: currentUserDocId,
        user2Id: otherUserDocId,
      );
      
      if (conversationId == null) {
        print('ERROR: Failed to create conversation');
        return;
      }
      
      print('✓ Created conversation: $conversationId');
    } else {
      final conversationId = conversationsQuery.docs.first.id;
      print('✓ Found existing conversation: $conversationId');
    }
    
    // 5. Test sending a message
    final testConversationId = conversationsQuery.docs.isNotEmpty 
        ? conversationsQuery.docs.first.id 
        : ConversationService.generateConversationId(currentUserDocId, 'test_user');
    
    print('\\nTesting message send to conversation: $testConversationId');
    
    // Test direct Cloud Function call
    print('\\nTest 1: Direct Cloud Function call...');
    try {
      final result = await cloudFunctions.sendChatMessage(
        conversationId: testConversationId,
        message: 'Test message from debug script',
      );
      print('✓ Cloud Function result: $result');
    } catch (e) {
      print('✗ Cloud Function error: $e');
    }
    
    // Test through ConversationService
    print('\\nTest 2: Through ConversationService...');
    try {
      final success = await conversationService.sendMessage(
        conversationId: testConversationId,
        message: 'Test message through service',
      );
      print(success ? '✓ Message sent successfully' : '✗ Failed to send message');
    } catch (e) {
      print('✗ ConversationService error: $e');
    }
    
    // Check if message was written to Firestore
    print('\\nChecking messages in Firestore...');
    final messagesQuery = await FirebaseFirestore.instance
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .doc(testConversationId)
        .collection('messages')
        .orderBy('sent_at', descending: true)
        .limit(5)
        .get();
    
    print('Found ${messagesQuery.docs.length} messages in conversation');
    for (var doc in messagesQuery.docs) {
      final data = doc.data();
      print('  - Message ID: ${doc.id}');
      print('    Sender: ${data['sender_id']}');
      print('    Message: ${data['message']}');
      print('    Sent at: ${data['sent_at']}');
    }
    
  } catch (e, stack) {
    print('\\nERROR: $e');
    print('Stack trace: $stack');
  }
  
  print('\\n=== DEBUG TEST COMPLETE ===');
}