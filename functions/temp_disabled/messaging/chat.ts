import * as functions from 'firebase-functions';
import { verifyAuth } from '../utils/auth';
import { getUniversityCollection, createDocument, queryCollection } from '../utils/database';
import { Message } from '../types';

interface SendMessageData {
  universityPath: string;
  chat_id: string;
  message: string;
  recipient_id?: string;
}

interface GetChatHistoryData {
  universityPath: string;
  chat_id: string;
  limit?: number;
  offset?: number;
}

/**
 * Send a message in a chat
 */
export const sendMessage = functions.https.onCall(async (data: SendMessageData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, chat_id, message, recipient_id } = data;
    
    // Validate input
    if (!chat_id || !message || message.trim().length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Chat ID and message required');
    }

    if (message.length > 1000) {
      throw new functions.https.HttpsError('invalid-argument', 'Message too long (max 1000 characters)');
    }

    // TODO: Add permission check to verify user can send messages in this chat
    // This would require checking if the user is part of the mentor-mentee relationship

    // Create message document
    const messageDoc: Omit<Message, 'id'> = {
      chat_id,
      sender_id: authContext.uid,
      message: message.trim(),
      sent_at: new Date()
    };

    const messagesCollection = getUniversityCollection(universityPath, 'messages');
    const result = await createDocument(messagesCollection, messageDoc);

    if (result.success) {
      console.log(`Message sent: ${result.data?.id} in chat ${chat_id}`);
      
      // TODO: Send push notification to recipient
      if (recipient_id) {
        // Implementation for push notifications would go here
      }
    }

    return result;

  } catch (error) {
    console.error('Error sending message:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to send message');
  }
});

/**
 * Get chat history
 */
export const getChatHistory = functions.https.onCall(async (data: GetChatHistoryData, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, chat_id, limit = 50, offset = 0 } = data;
    
    if (!chat_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Chat ID required');
    }

    // TODO: Add permission check to verify user can access this chat

    const messagesCollection = getUniversityCollection(universityPath, 'messages');
    
    // Query messages for this chat
    const result = await queryCollection<Message>(messagesCollection, [
      { field: 'chat_id', operator: '==', value: chat_id }
    ]);

    if (result.success && result.data) {
      // Sort by sent_at descending and apply pagination
      const sortedMessages = result.data
        .sort((a, b) => new Date(b.sent_at).getTime() - new Date(a.sent_at).getTime())
        .slice(offset, offset + limit);

      return {
        success: true,
        data: sortedMessages,
        total: result.data.length,
        limit,
        offset
      };
    }

    return result;

  } catch (error) {
    console.error('Error getting chat history:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to get chat history');
  }
});

/**
 * Mark messages as read
 */
export const markMessagesAsRead = functions.https.onCall(async (data: {
  universityPath: string;
  chat_id: string;
  message_ids: string[];
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { chat_id, message_ids } = data;
    
    if (!chat_id || !message_ids || message_ids.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Chat ID and message IDs required');
    }

    // TODO: Implementation for marking messages as read
    // This could involve updating a separate read_status collection or field

    console.log(`Messages marked as read: ${message_ids.length} in chat ${chat_id} by ${authContext.uid}`);

    return {
      success: true,
      message: 'Messages marked as read'
    };

  } catch (error) {
    console.error('Error marking messages as read:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to mark messages as read');
  }
});

/**
 * Delete/Hide message for user
 */
export const hideMessage = functions.https.onCall(async (data: {
  universityPath: string;
  message_id: string;
}, context) => {
  try {
    // Verify authentication
    // const authContext = await verifyAuth(context);
    
    const { universityPath, message_id } = data;
    
    if (!message_id) {
      throw new functions.https.HttpsError('invalid-argument', 'Message ID required');
    }

    // Create entry in message_visibility table to hide message for this user
    const visibilityCollection = getUniversityCollection(universityPath, 'message_visibility');
    await createDocument(visibilityCollection, {
      user_id: authContext.uid,
      message_id,
      hidden_at: new Date()
    });

    console.log(`Message hidden: ${message_id} for user ${authContext.uid}`);

    return {
      success: true,
      message: 'Message hidden'
    };

  } catch (error) {
    console.error('Error hiding message:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to hide message');
  }
});