import * as functions from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';
import { verifyAuth } from '../utils/auth';
import { getDB, getUniversityPath, getUniversityCollection } from '../utils/database';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

interface CreateConversationData {
  user1Id: string;
  user2Id: string;
  mentorshipId?: string;
}

interface SendMessageData {
  conversationId: string;
  message: string;
  type?: 'text' | 'image' | 'file' | 'audio';
  media?: {
    url: string;
    thumbnail_url?: string;
    mime_type: string;
    size: number;
    width?: number;
    height?: number;
    filename?: string;
  };
}

interface MarkMessagesReadData {
  conversationId: string;
  messageIds: string[];
}

interface UpdateConversationSettingsData {
  conversationId: string;
  settings: {
    notifications_enabled?: boolean;
    archived?: boolean;
    pinned?: boolean;
    custom_nickname?: string;
  };
}

/**
 * Create a new conversation between two users
 */
export const createConversation = functions.https.onCall(
  async (data: CreateConversationData, context) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] createConversation: Starting function execution`);
    
    try {
      // Log incoming parameters
      console.log(`[${timestamp}] createConversation: Incoming parameters:`, {
        user1Id: data.user1Id,
        user2Id: data.user2Id,
        mentorshipId: data.mentorshipId,
        hasContext: !!context,
        hasAuth: !!context?.auth
      });
      
      // Verify authentication
      console.log(`[${timestamp}] createConversation: Verifying authentication...`);
      let authContext;
      try {
        authContext = await verifyAuth(context);
        console.log(`[${timestamp}] createConversation: Auth context details:`, {
          uid: authContext.uid,
          email: authContext.email,
          university_path: authContext.university_path,
          role: authContext.role
        });
      } catch (authError) {
        console.error(`[${timestamp}] createConversation: Authentication failed:`, authError);
        throw authError;
      }
      
      const universityPath = authContext.university_path || '';
      
      // Validate university path
      if (!universityPath) {
        console.error(`[${timestamp}] createConversation: University path not found in auth context`);
        throw new HttpsError('failed-precondition', 'University path not found in user context');
      }
      
      const { user1Id, user2Id, mentorshipId } = data;
      
      // Validate input
      if (!user1Id || !user2Id) {
        console.error(`[${timestamp}] createConversation: Missing user IDs:`, { user1Id, user2Id });
        throw new HttpsError('invalid-argument', 'Both user IDs are required');
      }
      
      console.log(`[${timestamp}] createConversation: Getting database instance...`);
      const db = getDB();
      console.log(`[${timestamp}] createConversation: Database instance obtained, university path:`, universityPath);
      
      // Get user details to verify the authenticated user is one of the participants
      console.log(`[${timestamp}] createConversation: Fetching participant details...`);
      const usersCollection = getUniversityCollection(universityPath, 'users');
      
      // Log the full path to the users collection
      const usersCollectionPath = `${universityPath}/data/users`;
      console.log(`[${timestamp}] createConversation: Users collection path:`, usersCollectionPath);
      
      let user1Doc, user2Doc;
      try {
        // Log the full paths to user documents being fetched
        const user1Path = `${usersCollectionPath}/${user1Id}`;
        const user2Path = `${usersCollectionPath}/${user2Id}`;
        console.log(`[${timestamp}] createConversation: Fetching user documents from paths:`, {
          user1Path,
          user2Path
        });
        
        [user1Doc, user2Doc] = await Promise.all([
          usersCollection.doc(user1Id).get(),
          usersCollection.doc(user2Id).get()
        ]);
        
        console.log(`[${timestamp}] createConversation: User documents fetched:`, {
          user1Exists: user1Doc.exists,
          user2Exists: user2Doc.exists,
          user1Id: user1Doc.id,
          user2Id: user2Doc.id
        });
      } catch (fetchError) {
        console.error(`[${timestamp}] createConversation: Error fetching user documents:`, fetchError);
        throw new HttpsError('internal', 'Failed to fetch user documents');
      }
      
      if (!user1Doc.exists || !user2Doc.exists) {
        console.error(`[${timestamp}] createConversation: User not found:`, {
          user1Exists: user1Doc.exists,
          user2Exists: user2Doc.exists
        });
        throw new HttpsError('not-found', 'One or both users not found');
      }
      
      const user1Data = user1Doc.data()!;
      const user2Data = user2Doc.data()!;
      
      console.log(`[${timestamp}] createConversation: Participant details:`, {
        user1: {
          id: user1Id,
          name: user1Data.name,
          userType: user1Data.userType,
          hasFirebaseUid: !!user1Data.firebase_uid
        },
        user2: {
          id: user2Id,
          name: user2Data.name,
          userType: user2Data.userType,
          hasFirebaseUid: !!user2Data.firebase_uid
        }
      });
      
      // Verify user is one of the participants by checking firebase_uid
      const user1FirebaseUid = user1Data.firebase_uid || '';
      const user2FirebaseUid = user2Data.firebase_uid || '';
      
      console.log(`[${timestamp}] createConversation: Verifying participant permission:`, {
        authUid: authContext.uid,
        user1FirebaseUid,
        user2FirebaseUid,
        isUser1: authContext.uid === user1FirebaseUid,
        isUser2: authContext.uid === user2FirebaseUid
      });
      
      if (authContext.uid !== user1FirebaseUid && authContext.uid !== user2FirebaseUid) {
        console.error(`[${timestamp}] createConversation: Permission denied - user not a participant`);
        throw new HttpsError('permission-denied', 'You must be a participant in the conversation');
      }
      
      // Create conversation ID with sorted user IDs for consistency
      // IDs are sorted alphabetically to ensure the same conversation ID
      // is generated regardless of the order the users are provided
      // Example: ["Emerald_Nash", "Dasarathi_Narayanan"] -> "Dasarathi_Narayanan__Emerald_Nash"
      const sortedIds = [user1Id, user2Id].sort();
      const conversationId = `${sortedIds[0]}__${sortedIds[1]}`;
      console.log(`[${timestamp}] createConversation: Generated conversation ID:`, conversationId);
      
      const conversationRef = db
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId);
      
      // Log the full path to the conversation document
      const conversationPath = `${universityPath}/data/conversations/${conversationId}`;
      console.log(`[${timestamp}] createConversation: Conversation document path:`, conversationPath);
      
      // Check if conversation already exists
      console.log(`[${timestamp}] createConversation: Checking if conversation exists at path:`, conversationPath);
      let existingConversation;
      try {
        existingConversation = await conversationRef.get();
        console.log(`[${timestamp}] createConversation: Conversation existence check:`, {
          exists: existingConversation.exists,
          conversationId,
          fullPath: conversationPath
        });
      } catch (checkError) {
        console.error(`[${timestamp}] createConversation: Error checking existing conversation:`, checkError);
        throw new HttpsError('internal', 'Failed to check existing conversation');
      }
      
      if (existingConversation.exists) {
        console.log(`[${timestamp}] createConversation: Conversation already exists, returning existing`);
        return {
          success: true,
          conversationId,
          message: 'Conversation already exists',
          isNew: false
        };
      }
      
      // Create conversation document
      console.log(`[${timestamp}] createConversation: Creating new conversation document...`);
      
      // Debug: Check if admin.firestore is available
      console.log(`[${timestamp}] createConversation: Checking admin.firestore availability:`, {
        hasAdmin: !!admin,
        hasFirestore: !!admin.firestore,
        hasFieldValue: !!admin.firestore?.FieldValue,
        hasServerTimestamp: !!admin.firestore?.FieldValue?.serverTimestamp
      });
      
      // Debug: Log the exact data being used
      console.log(`[${timestamp}] createConversation: Building conversation data with:`, {
        user1Id,
        user1Name: user1Data.name,
        user1UserType: user1Data.userType,
        user2Id,
        user2Name: user2Data.name,
        user2UserType: user2Data.userType,
        sortedIds
      });
      
      let conversationData: any;
      try {
        // Build the conversation data with error checking
        conversationData = {
          participants: sortedIds,
          participant_details: {
            [user1Id]: {
              name: user1Data.name || '',
              userType: user1Data.userType || 'mentee',
              joined_at: FieldValue.serverTimestamp()
            },
            [user2Id]: {
              name: user2Data.name || '',
              userType: user2Data.userType || 'mentee',
              joined_at: FieldValue.serverTimestamp()
            }
          },
          last_message: null,
          created_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          type: 'direct',
          metadata: mentorshipId ? {
            mentorship_id: mentorshipId,
            academic_year: new Date().getFullYear().toString()
          } : {},
          user_settings: {
            [user1Id]: {
              last_read: FieldValue.serverTimestamp(),
              unread_count: 0,
              notifications_enabled: true,
              archived: false,
              pinned: false,
              custom_nickname: null
            },
            [user2Id]: {
              last_read: FieldValue.serverTimestamp(),
              unread_count: 0,
              notifications_enabled: true,
              archived: false,
              pinned: false,
              custom_nickname: null
            }
          }
        };
        
        console.log(`[${timestamp}] createConversation: Successfully built conversation data object`);
      } catch (buildError) {
        console.error(`[${timestamp}] createConversation: Error building conversation data:`, buildError);
        if (buildError instanceof Error) {
          console.error(`[${timestamp}] createConversation: Build error message:`, buildError.message);
          console.error(`[${timestamp}] createConversation: Build error stack:`, buildError.stack);
        }
        throw new HttpsError('internal', `Failed to build conversation data: ${buildError instanceof Error ? buildError.message : 'Unknown error'}`);
      }
      
      console.log(`[${timestamp}] createConversation: Conversation data prepared:`, {
        participants: conversationData.participants,
        type: conversationData.type,
        hasMetadata: !!conversationData.metadata,
        mentorshipId: conversationData.metadata?.mentorship_id
      });
      
      try {
        console.log(`[${timestamp}] createConversation: Writing conversation to Firestore at path:`, conversationPath);
        
        // Debug: Log the actual data being written (without FieldValue objects)
        console.log(`[${timestamp}] createConversation: Conversation data structure:`, {
          hasParticipants: !!conversationData.participants,
          participantCount: conversationData.participants?.length,
          hasParticipantDetails: !!conversationData.participant_details,
          participantDetailKeys: Object.keys(conversationData.participant_details || {}),
          hasUserSettings: !!conversationData.user_settings,
          userSettingKeys: Object.keys(conversationData.user_settings || {}),
          dataKeys: Object.keys(conversationData)
        });
        
        // Debug: Check conversationRef
        console.log(`[${timestamp}] createConversation: ConversationRef details:`, {
          hasRef: !!conversationRef,
          refPath: conversationRef?.path,
          refId: conversationRef?.id
        });
        
        await conversationRef.set(conversationData);
        console.log(`[${timestamp}] createConversation: Successfully written to Firestore at path:`, conversationPath);
        
        // Log the messages subcollection path
        const messagesSubcollectionPath = `${conversationPath}/messages`;
        console.log(`[${timestamp}] createConversation: Messages subcollection created at path:`, messagesSubcollectionPath);
      } catch (writeError) {
        console.error(`[${timestamp}] createConversation: Error writing to Firestore at path ${conversationPath}:`, writeError);
        if (writeError instanceof Error) {
          console.error(`[${timestamp}] createConversation: Write error stack:`, writeError.stack);
          console.error(`[${timestamp}] createConversation: Write error message:`, writeError.message);
        }
        throw new HttpsError('internal', 'Failed to create conversation in database');
      }
      
      console.log(`[${timestamp}] createConversation: Conversation created successfully:`, {
        conversationId,
        createdBy: authContext.uid,
        participants: sortedIds
      });
      
      return {
        success: true,
        conversationId,
        message: 'Conversation created successfully',
        isNew: true
      };
      
    } catch (error) {
      const errorTimestamp = new Date().toISOString();
      console.error(`[${errorTimestamp}] createConversation: Error in main try block:`, error);
      if (error instanceof Error) {
        console.error(`[${errorTimestamp}] createConversation: Error stack trace:`, error.stack);
        console.error(`[${errorTimestamp}] createConversation: Error details:`, {
          name: error.name,
          message: error.message,
          // Check if it's a FieldValue error
          isFieldValueError: error.message?.includes('serverTimestamp') || error.message?.includes('FieldValue'),
          errorString: error.toString()
        });
        
        // Additional debugging for specific error types
        if (error.message?.includes('serverTimestamp') || error.message?.includes('FieldValue')) {
          console.error(`[${errorTimestamp}] createConversation: FieldValue error detected!`);
          console.error(`[${errorTimestamp}] createConversation: Admin status at error time:`, {
            hasAdmin: !!admin,
            hasFirestore: !!admin?.firestore,
            hasFieldValue: !!admin?.firestore?.FieldValue,
            adminType: typeof admin,
            firestoreType: typeof admin?.firestore
          });
        }
      }
      if (error instanceof HttpsError) {
        console.error(`[${errorTimestamp}] createConversation: HttpsError details:`, {
          code: error.code,
          details: error.details
        });
      }
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', 'Failed to create conversation');
    }
  }
);

/**
 * Send a message in a conversation
 */
export const sendMessage = functions.https.onCall(
  async (data: SendMessageData, context) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] sendMessage: Starting function execution`);
    
    try {
      // Log incoming parameters
      console.log(`[${timestamp}] sendMessage: Incoming parameters:`, {
        conversationId: data.conversationId,
        messageLength: data.message?.length,
        type: data.type || 'text',
        hasMedia: !!data.media,
        hasContext: !!context,
        hasAuth: !!context?.auth
      });
      
      // Verify authentication
      console.log(`[${timestamp}] sendMessage: Verifying authentication...`);
      const authContext = await verifyAuth(context);
      const universityPath = authContext.university_path || '';
      
      console.log(`[${timestamp}] sendMessage: Auth context:`, {
        uid: authContext.uid,
        email: authContext.email,
        university_path: universityPath,
        role: authContext.role
      });
      
      // Validate university path
      if (!universityPath) {
        console.error(`[${timestamp}] sendMessage: University path not found`);
        throw new HttpsError('failed-precondition', 'University path not found in user context');
      }
      
      const { conversationId, message, type = 'text', media } = data;
      
      // Validate input
      if (!conversationId || !message) {
        console.error(`[${timestamp}] sendMessage: Missing required fields:`, { conversationId, hasMessage: !!message });
        throw new HttpsError('invalid-argument', 'Conversation ID and message are required');
      }
      
      if (message.length > 5000) {
        console.error(`[${timestamp}] sendMessage: Message too long:`, message.length);
        throw new HttpsError('invalid-argument', 'Message is too long (max 5000 characters)');
      }
      
      const db = getDB();
      
      // Log the Firestore path for conversation
      const conversationPath = `${universityPath}/data/conversations/${conversationId}`;
      console.log(`[${timestamp}] sendMessage: Firestore conversation path:`, conversationPath);
      
      const conversationRef = db
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId);
      
      // Verify conversation exists and user is a participant
      console.log(`[${timestamp}] sendMessage: Fetching conversation document...`);
      const conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        console.error(`[${timestamp}] sendMessage: Conversation not found:`, conversationId);
        throw new HttpsError('not-found', 'Conversation not found');
      }
      
      console.log(`[${timestamp}] sendMessage: Conversation found, verifying participant...`);
      const conversationData = conversationDoc.data()!;
      const participants = conversationData.participants || [];
      
      // Get the current user's document ID from Firebase UID
      let currentUserDocId: string;
      
      // First try to find by firebase_uid (production scenario)
      const usersPath = `${universityPath}/users`;
      console.log(`[${timestamp}] sendMessage: Querying users collection at path:`, usersPath);
      
      const usersCollection = getUniversityCollection(universityPath, 'users');
      const userSnapshot = await usersCollection
        .where('firebase_uid', '==', authContext.uid)
        .limit(1)
        .get();
      
      if (!userSnapshot.empty) {
        currentUserDocId = userSnapshot.docs[0].id;
        console.log(`[${timestamp}] sendMessage: Found user by firebase_uid, document ID:`, currentUserDocId);
      } else {
        // Fallback for emulator: check if the auth UID matches a document ID directly
        console.log(`[${timestamp}] sendMessage: No user found by firebase_uid, checking if UID is a document ID...`);
        
        // Check if a user document exists with the auth UID as the document ID
        const userDocRef = usersCollection.doc(authContext.uid);
        const userDoc = await userDocRef.get();
        
        if (userDoc.exists) {
          currentUserDocId = authContext.uid;
          console.log(`[${timestamp}] sendMessage: Found user by document ID:`, currentUserDocId);
        } else {
          // Final fallback: check by email
          console.log(`[${timestamp}] sendMessage: Checking by email:`, authContext.email);
          const emailSnapshot = await usersCollection
            .where('email', '==', authContext.email)
            .limit(1)
            .get();
          
          if (!emailSnapshot.empty) {
            currentUserDocId = emailSnapshot.docs[0].id;
            console.log(`[${timestamp}] sendMessage: Found user by email, document ID:`, currentUserDocId);
          } else {
            console.error(`[${timestamp}] sendMessage: User profile not found by any method`);
            throw new HttpsError('not-found', 'User profile not found');
          }
        }
      }
      
      // Verify user is a participant using document ID
      if (!participants.includes(currentUserDocId)) {
        console.error(`[${timestamp}] sendMessage: User not a participant:`, {
          currentUserDocId,
          participants
        });
        throw new HttpsError('permission-denied', 'You are not a participant in this conversation');
      }
      
      console.log(`[${timestamp}] sendMessage: User verified as participant`);
      
      // Create message document
      const messageData: any = {
        sender_id: currentUserDocId,
        message,
        sent_at: FieldValue.serverTimestamp(),
        type,
        status: 'sent',
        read_by: {
          [currentUserDocId]: FieldValue.serverTimestamp()
        },
        reactions: {},
        metadata: {}
      };
      
      // Add media data if provided
      if (media && type !== 'text') {
        messageData.media = media;
        console.log(`[${timestamp}] sendMessage: Adding media data:`, {
          url: media.url,
          type: media.mime_type,
          size: media.size
        });
      }
      
      // Use batch to atomically update conversation and add message
      const batch = db.batch();
      
      // Add message to subcollection
      const messageRef = conversationRef.collection('messages').doc();
      const messagePath = `${conversationPath}/messages/${messageRef.id}`;
      console.log(`[${timestamp}] sendMessage: Writing message to path:`, messagePath);
      
      batch.set(messageRef, messageData);
      
      // Get recipient ID
      const recipientId = conversationData.participants.find((id: string) => id !== currentUserDocId);
      console.log(`[${timestamp}] sendMessage: Recipient ID:`, recipientId);
      
      // Update conversation document
      const conversationUpdate: any = {
        last_message: {
          text: message,
          sender_id: currentUserDocId,
          timestamp: FieldValue.serverTimestamp()
        },
        updated_at: FieldValue.serverTimestamp()
      };
      
      // Increment unread count for recipient
      if (recipientId) {
        conversationUpdate[`user_settings.${recipientId}.unread_count`] = FieldValue.increment(1);
        console.log(`[${timestamp}] sendMessage: Incrementing unread count for recipient:`, recipientId);
      }
      
      console.log(`[${timestamp}] sendMessage: Updating conversation document at path:`, conversationPath);
      batch.update(conversationRef, conversationUpdate);
      
      // Commit the batch
      console.log(`[${timestamp}] sendMessage: Committing batch write...`);
      await batch.commit();
      
      console.log(`[${timestamp}] sendMessage: Message sent successfully:`, {
        conversationId,
        messageId: messageRef.id,
        senderId: currentUserDocId,
        recipientId
      });
      
      return {
        success: true,
        messageId: messageRef.id,
        message: 'Message sent successfully'
      };
      
    } catch (error) {
      const errorTimestamp = new Date().toISOString();
      console.error(`[${errorTimestamp}] sendMessage: Error in main try block:`, error);
      if (error instanceof Error) {
        console.error(`[${errorTimestamp}] sendMessage: Error stack:`, error.stack);
        console.error(`[${errorTimestamp}] sendMessage: Error details:`, {
          name: error.name,
          message: error.message
        });
      }
      if (error instanceof HttpsError) {
        console.error(`[${errorTimestamp}] sendMessage: HttpsError code:`, error.code);
      }
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', 'Failed to send message');
    }
  }
);

/**
 * Mark messages as read
 */
export const markMessagesRead = functions.https.onCall(
  async (data: MarkMessagesReadData, context) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] markMessagesRead: Starting function execution`);
    
    try {
      // Log incoming parameters
      console.log(`[${timestamp}] markMessagesRead: Incoming parameters:`, {
        conversationId: data.conversationId,
        messageCount: data.messageIds?.length,
        messageIds: data.messageIds,
        hasContext: !!context,
        hasAuth: !!context?.auth
      });
      
      // Verify authentication
      console.log(`[${timestamp}] markMessagesRead: Verifying authentication...`);
      const authContext = await verifyAuth(context);
      const universityPath = authContext.university_path || '';
      
      console.log(`[${timestamp}] markMessagesRead: Auth context:`, {
        uid: authContext.uid,
        email: authContext.email,
        university_path: universityPath,
        role: authContext.role
      });
      
      // Validate university path
      if (!universityPath) {
        console.error(`[${timestamp}] markMessagesRead: University path not found`);
        throw new HttpsError('failed-precondition', 'University path not found in user context');
      }
      
      const { conversationId, messageIds } = data;
      
      // Validate input
      if (!conversationId || !messageIds || messageIds.length === 0) {
        console.error(`[${timestamp}] markMessagesRead: Invalid input:`, {
          conversationId,
          hasMessageIds: !!messageIds,
          messageIdsLength: messageIds?.length
        });
        throw new HttpsError('invalid-argument', 'Conversation ID and message IDs are required');
      }
      
      const db = getDB();
      
      // Log the Firestore path for conversation
      const conversationPath = `${universityPath}/data/conversations/${conversationId}`;
      console.log(`[${timestamp}] markMessagesRead: Firestore conversation path:`, conversationPath);
      
      const conversationRef = db
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId);
      
      // Verify conversation exists and user is a participant
      console.log(`[${timestamp}] markMessagesRead: Fetching conversation document...`);
      const conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        console.error(`[${timestamp}] markMessagesRead: Conversation not found:`, conversationId);
        throw new HttpsError('not-found', 'Conversation not found');
      }
      
      console.log(`[${timestamp}] markMessagesRead: Conversation found, verifying participant...`);
      const conversationData = conversationDoc.data()!;
      const participants = conversationData.participants || [];
      
      // Get the current user's document ID from Firebase UID
      const usersPath = `${universityPath}/users`;
      console.log(`[${timestamp}] markMessagesRead: Querying users collection at path:`, usersPath);
      
      const usersCollection = getUniversityCollection(universityPath, 'users');
      const userSnapshot = await usersCollection
        .where('firebase_uid', '==', authContext.uid)
        .limit(1)
        .get();
      
      if (userSnapshot.empty) {
        console.error(`[${timestamp}] markMessagesRead: User profile not found for Firebase UID:`, authContext.uid);
        throw new HttpsError('not-found', 'User profile not found');
      }
      
      const currentUserDocId = userSnapshot.docs[0].id;
      console.log(`[${timestamp}] markMessagesRead: Current user document ID:`, currentUserDocId);
      
      // Verify user is a participant using document ID
      if (!participants.includes(currentUserDocId)) {
        console.error(`[${timestamp}] markMessagesRead: User not a participant:`, {
          currentUserDocId,
          participants
        });
        throw new HttpsError('permission-denied', 'You are not a participant in this conversation');
      }
      
      console.log(`[${timestamp}] markMessagesRead: User verified as participant`);
      
      const batch = db.batch();
      
      // Update each message's read status
      console.log(`[${timestamp}] markMessagesRead: Updating ${messageIds.length} messages...`);
      for (const messageId of messageIds) {
        const messageRef = conversationRef.collection('messages').doc(messageId);
        const messagePath = `${conversationPath}/messages/${messageId}`;
        console.log(`[${timestamp}] markMessagesRead: Updating message at path:`, messagePath);
        
        batch.update(messageRef, {
          status: 'read',
          [`read_by.${currentUserDocId}`]: FieldValue.serverTimestamp()
        });
      }
      
      // Reset unread count for the user
      const conversationUpdatePath = `${conversationPath}.user_settings.${currentUserDocId}`;
      console.log(`[${timestamp}] markMessagesRead: Resetting unread count at path:`, conversationUpdatePath);
      
      batch.update(conversationRef, {
        [`user_settings.${currentUserDocId}.unread_count`]: 0,
        [`user_settings.${currentUserDocId}.last_read`]: FieldValue.serverTimestamp()
      });
      
      console.log(`[${timestamp}] markMessagesRead: Committing batch update...`);
      await batch.commit();
      
      console.log(`[${timestamp}] markMessagesRead: Successfully marked ${messageIds.length} messages as read:`, {
        conversationId,
        messageIds,
        userId: currentUserDocId
      });
      
      return {
        success: true,
        message: `${messageIds.length} messages marked as read`
      };
      
    } catch (error) {
      const errorTimestamp = new Date().toISOString();
      console.error(`[${errorTimestamp}] markMessagesRead: Error in main try block:`, error);
      if (error instanceof Error) {
        console.error(`[${errorTimestamp}] markMessagesRead: Error stack:`, error.stack);
        console.error(`[${errorTimestamp}] markMessagesRead: Error details:`, {
          name: error.name,
          message: error.message
        });
      }
      if (error instanceof HttpsError) {
        console.error(`[${errorTimestamp}] markMessagesRead: HttpsError code:`, error.code);
      }
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', 'Failed to mark messages as read');
    }
  }
);

/**
 * Update conversation settings for a user
 */
export const updateConversationSettings = functions.https.onCall(
  async (data: UpdateConversationSettingsData, context) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] updateConversationSettings: Starting function execution`);
    
    try {
      // Log incoming parameters
      console.log(`[${timestamp}] updateConversationSettings: Incoming parameters:`, {
        conversationId: data.conversationId,
        settings: data.settings,
        hasContext: !!context,
        hasAuth: !!context?.auth
      });
      
      // Verify authentication
      console.log(`[${timestamp}] updateConversationSettings: Verifying authentication...`);
      const authContext = await verifyAuth(context);
      const universityPath = authContext.university_path || '';
      
      console.log(`[${timestamp}] updateConversationSettings: Auth context:`, {
        uid: authContext.uid,
        email: authContext.email,
        university_path: universityPath,
        role: authContext.role
      });
      
      // Validate university path
      if (!universityPath) {
        console.error(`[${timestamp}] updateConversationSettings: University path not found`);
        throw new HttpsError('failed-precondition', 'University path not found in user context');
      }
      
      const { conversationId, settings } = data;
      
      // Validate input
      if (!conversationId || !settings) {
        console.error(`[${timestamp}] updateConversationSettings: Invalid input:`, {
          conversationId,
          hasSettings: !!settings
        });
        throw new HttpsError('invalid-argument', 'Conversation ID and settings are required');
      }
      
      const db = getDB();
      
      // Log the Firestore path for conversation
      const conversationPath = `${universityPath}/data/conversations/${conversationId}`;
      console.log(`[${timestamp}] updateConversationSettings: Firestore conversation path:`, conversationPath);
      
      const conversationRef = db
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .doc(conversationId);
      
      // Verify conversation exists and user is a participant
      console.log(`[${timestamp}] updateConversationSettings: Fetching conversation document...`);
      const conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        console.error(`[${timestamp}] updateConversationSettings: Conversation not found:`, conversationId);
        throw new HttpsError('not-found', 'Conversation not found');
      }
      
      console.log(`[${timestamp}] updateConversationSettings: Conversation found, verifying participant...`);
      const conversationData = conversationDoc.data()!;
      const participants = conversationData.participants || [];
      
      // Get the current user's document ID from Firebase UID
      const usersPath = `${universityPath}/users`;
      console.log(`[${timestamp}] updateConversationSettings: Querying users collection at path:`, usersPath);
      
      const usersCollection = getUniversityCollection(universityPath, 'users');
      const userSnapshot = await usersCollection
        .where('firebase_uid', '==', authContext.uid)
        .limit(1)
        .get();
      
      if (userSnapshot.empty) {
        console.error(`[${timestamp}] updateConversationSettings: User profile not found for Firebase UID:`, authContext.uid);
        throw new HttpsError('not-found', 'User profile not found');
      }
      
      const currentUserDocId = userSnapshot.docs[0].id;
      console.log(`[${timestamp}] updateConversationSettings: Current user document ID:`, currentUserDocId);
      
      // Verify user is a participant using document ID
      if (!participants.includes(currentUserDocId)) {
        console.error(`[${timestamp}] updateConversationSettings: User not a participant:`, {
          currentUserDocId,
          participants
        });
        throw new HttpsError('permission-denied', 'You are not a participant in this conversation');
      }
      
      console.log(`[${timestamp}] updateConversationSettings: User verified as participant`);
      
      // Build update object for user settings
      const updateData: any = {};
      const updatedFields: string[] = [];
      
      if (settings.notifications_enabled !== undefined) {
        updateData[`user_settings.${currentUserDocId}.notifications_enabled`] = settings.notifications_enabled;
        updatedFields.push('notifications_enabled');
      }
      if (settings.archived !== undefined) {
        updateData[`user_settings.${currentUserDocId}.archived`] = settings.archived;
        updatedFields.push('archived');
      }
      if (settings.pinned !== undefined) {
        updateData[`user_settings.${currentUserDocId}.pinned`] = settings.pinned;
        updatedFields.push('pinned');
      }
      if (settings.custom_nickname !== undefined) {
        updateData[`user_settings.${currentUserDocId}.custom_nickname`] = settings.custom_nickname;
        updatedFields.push('custom_nickname');
      }
      
      console.log(`[${timestamp}] updateConversationSettings: Updating fields:`, {
        fields: updatedFields,
        updateData
      });
      
      // Log the update paths
      Object.keys(updateData).forEach(key => {
        console.log(`[${timestamp}] updateConversationSettings: Updating path:`, `${conversationPath}.${key}`);
      });
      
      // Update conversation
      console.log(`[${timestamp}] updateConversationSettings: Updating conversation document...`);
      await conversationRef.update(updateData);
      
      console.log(`[${timestamp}] updateConversationSettings: Settings updated successfully:`, {
        conversationId,
        userId: currentUserDocId,
        updatedFields
      });
      
      return {
        success: true,
        message: 'Conversation settings updated successfully'
      };
      
    } catch (error) {
      const errorTimestamp = new Date().toISOString();
      console.error(`[${errorTimestamp}] updateConversationSettings: Error in main try block:`, error);
      if (error instanceof Error) {
        console.error(`[${errorTimestamp}] updateConversationSettings: Error stack:`, error.stack);
        console.error(`[${errorTimestamp}] updateConversationSettings: Error details:`, {
          name: error.name,
          message: error.message
        });
      }
      if (error instanceof HttpsError) {
        console.error(`[${errorTimestamp}] updateConversationSettings: HttpsError code:`, error.code);
      }
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', 'Failed to update conversation settings');
    }
  }
);

/**
 * Get conversations for the authenticated user
 */
export const getUserConversations = functions.https.onCall(
  async (data: { limit?: number; lastConversationId?: string }, context) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] getUserConversations: Starting function execution`);
    
    try {
      // Log incoming parameters
      console.log(`[${timestamp}] getUserConversations: Incoming parameters:`, {
        limit: data.limit || 20,
        lastConversationId: data.lastConversationId,
        hasContext: !!context,
        hasAuth: !!context?.auth
      });
      
      // Verify authentication
      console.log(`[${timestamp}] getUserConversations: Verifying authentication...`);
      const authContext = await verifyAuth(context);
      const universityPath = authContext.university_path || '';
      
      console.log(`[${timestamp}] getUserConversations: Auth context:`, {
        uid: authContext.uid,
        email: authContext.email,
        university_path: universityPath,
        role: authContext.role
      });
      
      // Validate university path
      if (!universityPath) {
        console.error(`[${timestamp}] getUserConversations: University path not found`);
        throw new HttpsError('failed-precondition', 'University path not found in user context');
      }
      
      const { limit = 20, lastConversationId } = data;
      
      // Get the current user's document ID from Firebase UID
      const usersPath = `${universityPath}/users`;
      console.log(`[${timestamp}] getUserConversations: Querying users collection at path:`, usersPath);
      
      const usersCollection = getUniversityCollection(universityPath, 'users');
      const userSnapshot = await usersCollection
        .where('firebase_uid', '==', authContext.uid)
        .limit(1)
        .get();
      
      if (userSnapshot.empty) {
        console.error(`[${timestamp}] getUserConversations: User profile not found for Firebase UID:`, authContext.uid);
        throw new HttpsError('not-found', 'User profile not found');
      }
      
      const currentUserDocId = userSnapshot.docs[0].id;
      console.log(`[${timestamp}] getUserConversations: Current user document ID:`, currentUserDocId);
      
      const db = getDB();
      
      // Log the query path
      const conversationsPath = `${universityPath}/data/conversations`;
      console.log(`[${timestamp}] getUserConversations: Querying conversations at path:`, conversationsPath);
      console.log(`[${timestamp}] getUserConversations: Query parameters:`, {
        arrayContains: currentUserDocId,
        orderBy: 'updated_at desc',
        limit
      });
      
      let query = db
        .collection(universityPath)
        .doc('data')
        .collection('conversations')
        .where('participants', 'array-contains', currentUserDocId)
        .orderBy('updated_at', 'desc')
        .limit(limit);
      
      // Pagination support
      if (lastConversationId) {
        console.log(`[${timestamp}] getUserConversations: Pagination requested, starting after:`, lastConversationId);
        const lastDocPath = `${conversationsPath}/${lastConversationId}`;
        console.log(`[${timestamp}] getUserConversations: Fetching last document at path:`, lastDocPath);
        
        const lastDoc = await db
          .collection(universityPath)
          .doc('data')
          .collection('conversations')
          .doc(lastConversationId)
          .get();
        
        if (lastDoc.exists) {
          query = query.startAfter(lastDoc);
          console.log(`[${timestamp}] getUserConversations: Pagination starting after document found`);
        } else {
          console.warn(`[${timestamp}] getUserConversations: Last conversation ID not found:`, lastConversationId);
        }
      }
      
      console.log(`[${timestamp}] getUserConversations: Executing query...`);
      const snapshot = await query.get();
      
      console.log(`[${timestamp}] getUserConversations: Query results:`, {
        conversationCount: snapshot.size,
        empty: snapshot.empty
      });
      
      const conversations = snapshot.docs.map(doc => {
        const data = doc.data();
        const userSettings = data.user_settings?.[currentUserDocId] || {};
        
        const conversationPath = `${conversationsPath}/${doc.id}`;
        console.log(`[${timestamp}] getUserConversations: Processing conversation at path:`, conversationPath);
        
        return {
          id: doc.id,
          ...data,
          // Include user-specific settings at top level for convenience
          unread_count: userSettings.unread_count || 0,
          last_read: userSettings.last_read,
          archived: userSettings.archived || false,
          pinned: userSettings.pinned || false,
          notifications_enabled: userSettings.notifications_enabled !== false,
          custom_nickname: userSettings.custom_nickname
        };
      });
      
      console.log(`[${timestamp}] getUserConversations: Processed ${conversations.length} conversations`);
      console.log(`[${timestamp}] getUserConversations: Conversation IDs:`, conversations.map(c => c.id));
      
      return {
        success: true,
        conversations,
        hasMore: conversations.length === limit
      };
      
    } catch (error) {
      const errorTimestamp = new Date().toISOString();
      console.error(`[${errorTimestamp}] getUserConversations: Error in main try block:`, error);
      if (error instanceof Error) {
        console.error(`[${errorTimestamp}] getUserConversations: Error stack:`, error.stack);
        console.error(`[${errorTimestamp}] getUserConversations: Error details:`, {
          name: error.name,
          message: error.message
        });
      }
      if (error instanceof HttpsError) {
        console.error(`[${errorTimestamp}] getUserConversations: HttpsError code:`, error.code);
      }
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', 'Failed to get conversations');
    }
  }
);