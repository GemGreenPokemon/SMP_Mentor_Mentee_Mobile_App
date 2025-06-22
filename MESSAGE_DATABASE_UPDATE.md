# Message Database Structure Update

## Overview
This document outlines the migration from a user-centric message storage structure to a conversation-centric structure that better supports real-time messaging features and scalability.

## Current Structure (User-Centric)

```
{universityPath}/  (dynamically retrieved from CloudFunctionService)
└── data/
    └── users/
        ├── {userDocId1}/  (e.g., "Emerald_Nash")
        │   └── messages/
        │       ├── {auto-generated-id-1}/
        │       │   ├── chat_id: "Dasarathi_Narayanan__Emerald_Nash"
        │       │   ├── sender_id: "Emerald_Nash"
        │       │   ├── message: "Hey, how are you?"
        │       │   ├── sent_at: timestamp
        │       │   └── synced: true
        │       │
        │       └── {auto-generated-id-2}/
        │           ├── chat_id: "Dasarathi_Narayanan__Emerald_Nash"
        │           ├── sender_id: "Dasarathi_Narayanan"
        │           ├── message: "I'm good, thanks!"
        │           ├── sent_at: timestamp
        │           └── synced: true
        │
        └── {userDocId2}/  (e.g., "Dasarathi_Narayanan")
            └── messages/
                └── [DUPLICATE copies of same messages]
```

### Current Structure Issues
1. **Data Duplication**: Each message stored twice (sender + recipient)
2. **Sync Complexity**: Hard to maintain consistency between copies
3. **Limited Features**: Difficult to implement read receipts, reactions, "delete for everyone"
4. **Query Performance**: Must filter through all user messages to find conversation
5. **Storage Cost**: 2x storage for every message

## New Structure (Conversation-Centric)

```
{universityPath}/  (dynamically retrieved from CloudFunctionService)
└── data/
    ├── conversations/
    │   └── {conversationId}/  (e.g., "Dasarathi_Narayanan__Emerald_Nash")
    │       ├── participants: ["Dasarathi_Narayanan", "Emerald_Nash"]
    │       ├── participant_details: {
    │       │     "Dasarathi_Narayanan": {
    │       │         "name": "Dasarathi Narayanan",
    │       │         "role": "mentee",
    │       │         "joined_at": timestamp
    │       │     },
    │       │     "Emerald_Nash": {
    │       │         "name": "Emerald Nash",
    │       │         "role": "mentor",
    │       │         "joined_at": timestamp
    │       │     }
    │       │   }
    │       ├── last_message: {
    │       │     "text": "I'm good, thanks!",
    │       │     "sender_id": "Dasarathi_Narayanan",
    │       │     "timestamp": serverTimestamp
    │       │   }
    │       ├── created_at: serverTimestamp
    │       ├── updated_at: serverTimestamp
    │       ├── type: "direct"  // "direct" or "group"
    │       ├── metadata: {
    │       │     "mentorship_id": "mentorship_123",  // Link to mentorship record
    │       │     "academic_year": "2024-2025"
    │       │   }
    │       ├── user_settings: {
    │       │     "Dasarathi_Narayanan": {
    │       │         "last_read": timestamp,
    │       │         "unread_count": 0,
    │       │         "notifications_enabled": true,
    │       │         "archived": false,
    │       │         "pinned": false,
    │       │         "custom_nickname": null
    │       │     },
    │       │     "Emerald_Nash": {
    │       │         "last_read": timestamp,
    │       │         "unread_count": 2,
    │       │         "notifications_enabled": true,
    │       │         "archived": false,
    │       │         "pinned": true,
    │       │         "custom_nickname": "Dasarathi - Mentee"
    │       │     }
    │       │   }
    │       │
    │       └── messages/ (subcollection)
    │           └── {auto-generated-message-id}/
    │               ├── sender_id: "Emerald_Nash"
    │               ├── message: "Hey, how are you?"
    │               ├── sent_at: serverTimestamp
    │               ├── type: "text"  // "text", "image", "file", "audio"
    │               ├── status: "read"  // "sent", "delivered", "read"
    │               ├── read_by: {
    │               │     "Emerald_Nash": timestamp,
    │               │     "Dasarathi_Narayanan": timestamp
    │               │   }
    │               ├── reactions: {
    │               │     "👍": ["Dasarathi_Narayanan"]
    │               │   }
    │               └── metadata: {}  // For future extensibility
    │
    └── users/
        ├── {userDocId1}/  (e.g., "Emerald_Nash")
        │   └── [existing user profile data - NO conversations subcollection]
        │
        └── {userDocId2}/  (e.g., "Dasarathi_Narayanan")
            └── [existing user profile data - NO conversations subcollection]

## Important Design Decision: No User Conversations Subcollection

We are NOT creating a conversations subcollection under users. Instead, all user-specific conversation metadata (unread count, last read, muted, archived, etc.) will be stored directly in the conversation document. This simplifies the structure and reduces the number of queries needed.
```

## Cloud Functions Database Initialization

### Current Implementation
The database structure is initialized in FOUR places:

1. **University Initialization** (`functions/src/university/initialization.ts`):
   - Creates a `messages` collection at university level
   - Path: `{universityPath}/data/messages/_metadata`
   - Currently creates an empty collection with metadata

2. **User Creation via Cloud Functions** (`functions/src/users/management.ts` + `functions/src/utils/database.ts`):
   - **Single User Creation**: `createUser` function (line 110) calls `initializeUserSubcollections`
   - **Bulk User Creation**: `bulkCreateUsers` function (line 489) calls `initializeUserSubcollections`
   - Creates `messages` subcollection for each user
   - Path: `{universityPath}/data/users/{userId}/messages/_metadata`
   - The `initializeUserSubcollections()` function creates these subcollections:
     - `checklists`
     - `availability`
     - `requestedMeetings`
     - `meetings`
     - `messages` ← THIS NEEDS TO BE REMOVED
     - `notes`
     - `ratings`

3. **Direct Database Initialization** (`lib/services/direct_database_service.dart`):
   - Used for development/testing bypassing Cloud Functions
   - Creates same `messages` collection at university level
   - Does NOT create user subcollections (only creates top-level collections)

4. **Excel Import Process** (`lib/screens/web/shared/web_settings/sections/excel_upload_section.dart`):
   - Calls `bulkCreateUsers` Cloud Function (line 701)
   - `bulkCreateUsers` internally calls `initializeUserSubcollections` for each user
   - This means imported users automatically get `messages` subcollection
   - No changes needed in Excel import - it will automatically use updated subcollections

### Required Cloud Function Updates

1. **Update University Initialization** (`functions/src/university/initialization.ts`):
   ```typescript
   // In initializeUniversity function, update collectionsToCreate:
   const collectionsToCreate = [
     'users',
     'mentorships',
     'meetings',
     'conversations',  // ADD THIS - replaces 'messages'
     // 'messages',     // REMOVE THIS
     'announcements',
     // ... rest of collections
   ];
   ```

   **Also update** (`lib/services/direct_database_service.dart`):
   ```dart
   // In initializeUniversityDirect function, update collectionsToCreate:
   final collectionsToCreate = [
     'users',
     'mentorships', 
     'meetings',
     'conversations',  // ADD THIS - replaces 'messages'
     // 'messages',     // REMOVE THIS
     'announcements',
     // ... rest of collections
   ];
   ```

2. **Update User Subcollections**:
   ```typescript
   // In initializeUserSubcollections, update subcollections array:
   const subcollections = [
     'checklists',
     'availability', 
     'requestedMeetings',
     'meetings',
     // 'messages',    // REMOVE THIS - messages now in conversations
     // NO conversations subcollection - user settings stored in conversation doc
     'notes',
     'ratings'
   ];
   ```

3. **Add Conversation Creation Function**:
   ```typescript
   // New function in functions/src/messaging/conversations.ts
   export const createConversation = functions.https.onCall(
     async (data: { user1Id: string; user2Id: string }, context) => {
       const authContext = await verifyAuth(context);
       const universityPath = getUniversityPath(context);
       
       // Verify user is one of the participants
       if (authContext.uid !== data.user1Id && authContext.uid !== data.user2Id) {
         throw new functions.https.HttpsError('permission-denied', 'Must be a participant');
       }
       
       // Create conversation with sorted IDs
       const sortedIds = [data.user1Id, data.user2Id].sort();
       const conversationId = `${sortedIds[0]}__${sortedIds[1]}`;
       
       // Rest of conversation creation logic...
     }
   );
   ```

## Migration Plan

### Phase 1: Preparation (Week 1)
1. **Create Migration Service**
   - Build `MessageMigrationService` class
   - Add dry-run capability to test without making changes
   - Implement progress tracking and logging

2. **Update Messaging Service**
   - Add feature flag to switch between old/new structure
   - Implement dual-write capability (write to both structures)
   - Create new query methods for conversation-centric structure

### Phase 2: Dual-Write Period (Week 2-3)
1. **Enable Dual Writing**
   - New messages write to both structures
   - Ensures no data loss during transition
   - Monitor for any sync issues

2. **Migrate Historical Data**
   - Run migration in batches (100 conversations at a time)
   - Verify data integrity after each batch
   - Create backup before migration

### Phase 3: Transition (Week 4)
1. **Switch Read Operations**
   - Update app to read from new structure
   - Keep dual-write enabled for safety
   - Monitor for any issues

2. **Verify and Clean Up**
   - Verify all messages migrated correctly
   - Disable dual-write after verification
   - Archive old message structure (don't delete immediately)

## Security Rules Update

### Current Rules
```javascript
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
  
  match /messages/{messageId} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

### New Rules
```javascript
// Conversations collection
match /conversations/{conversationId} {
  function isParticipant() {
    return request.auth.uid in resource.data.participants;
  }
  
  function isValidParticipant() {
    return request.auth.uid in request.resource.data.participants;
  }
  
  // Read conversation if participant
  allow read: if isParticipant();
  
  // Create conversation if user is a participant
  allow create: if isValidParticipant()
    && request.resource.data.participants.size() >= 2;
  
  // Update only specific fields
  allow update: if isParticipant()
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['participants', 'created_at']);
  
  // Messages subcollection
  match /messages/{messageId} {
    allow read: if isParticipant();
    
    allow create: if isParticipant()
      && request.auth.uid == request.resource.data.sender_id
      && request.resource.data.keys().hasAll(['message', 'sender_id', 'sent_at', 'type'])
      && request.resource.data.message is string
      && request.resource.data.message.size() > 0
      && request.resource.data.message.size() < 5000;
    
    // Messages are immutable (no edit/delete)
    allow update: if false;
    allow delete: if false;
  }
}

// NO user conversation subcollection - all user settings stored in conversation document
```

## Benefits of New Structure

1. **Performance**
   - Single query to get all messages in a conversation
   - Efficient pagination with subcollections
   - Faster conversation list loading

2. **Features Enabled**
   - Real-time read receipts
   - Message reactions
   - Typing indicators
   - "Delete for everyone" (soft delete)
   - Message search within conversation
   - Conversation-level settings (mute, archive, pin)

3. **Scalability**
   - Works with any university (uses dynamic paths)
   - Supports group chats (future feature)
   - Better for large message volumes
   - Reduced storage costs (no duplication)

4. **Data Integrity**
   - Single source of truth for messages
   - Consistent message history for all participants
   - Easier to implement message moderation

## Implementation Notes

1. **No Hardcoded Paths**
   - All paths use `CloudFunctionService.getCurrentUniversityPath()`
   - Supports multi-tenant architecture
   - Example: `{universityPath}/data/conversations/{conversationId}`

2. **Conversation ID Format**
   - Keep current format: `{userId1}__{userId2}`
   - Always sort IDs alphabetically for consistency
   - Example: `generateConversationId(user1, user2)`

3. **Backward Compatibility**
   - Keep old message reading logic during migration
   - Use feature flags to control rollout
   - Provide rollback capability

4. **Testing Strategy**
   - Unit tests for migration logic
   - Integration tests for dual-write
   - End-to-end tests for new structure
   - Performance benchmarks

## Monitoring and Success Metrics

1. **Migration Metrics**
   - Number of conversations migrated
   - Messages per conversation
   - Migration duration
   - Any errors or failures

2. **Performance Metrics**
   - Message query latency
   - Conversation list load time
   - Real-time update delay
   - Firestore read/write costs

3. **User Impact**
   - No downtime during migration
   - No message loss
   - Improved feature availability
   - Better performance

## Rollback Plan

If issues arise during migration:
1. Disable dual-write immediately
2. Revert app to read from old structure
3. Investigate and fix issues
4. Resume migration after fixes

## Timeline

- **Week 1**: Development and testing
- **Week 2-3**: Gradual migration with monitoring
- **Week 4**: Full transition and cleanup
- **Week 5**: Archive old structure and documentation

## Additional Implementation Details

### Conversation Creation Logic
```dart
// When creating a new conversation
Future<String> createConversation(String user1Id, String user2Id) async {
  // Always sort IDs for consistent conversation ID
  final sortedIds = [user1Id, user2Id]..sort();
  final conversationId = '${sortedIds[0]}__${sortedIds[1]}';
  
  // Check if conversation already exists
  final conversationRef = FirebaseFirestore.instance
    .collection(_universityPath)
    .doc('data')
    .collection('conversations')
    .doc(conversationId);
    
  final doc = await conversationRef.get();
  if (!doc.exists) {
    // Create new conversation
    await conversationRef.set({
      'participants': sortedIds,
      'participant_details': {
        user1Id: await getUserDetails(user1Id),
        user2Id: await getUserDetails(user2Id),
      },
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'type': 'direct',
      'last_message': null,
      // Initialize user settings directly in conversation
      'user_settings': {
        user1Id: {
          'last_read': FieldValue.serverTimestamp(),
          'unread_count': 0,
          'notifications_enabled': true,
          'archived': false,
          'pinned': false,
          'custom_nickname': null,
        },
        user2Id: {
          'last_read': FieldValue.serverTimestamp(),
          'unread_count': 0,
          'notifications_enabled': true,
          'archived': false,
          'pinned': false,
          'custom_nickname': null,
        },
      },
    });
    
    // NO user conversation references needed - all data in conversation doc
  }
  
  return conversationId;
}
```

### Typing Indicators Structure
```
{universityPath}/data/conversations/{conversationId}/
└── typing_status/ (subcollection)
    └── {userId}/
        ├── is_typing: true/false
        └── last_updated: serverTimestamp
```

### Unread Count Management
```dart
// When sending a message - update in conversation document
await batch.update(conversationRef, {
  'last_message': {
    'text': messageText,
    'sender_id': senderId,
    'timestamp': FieldValue.serverTimestamp(),
  },
  'updated_at': FieldValue.serverTimestamp(),
  // Increment unread for recipient directly in conversation
  'user_settings.$recipientId.unread_count': FieldValue.increment(1),
});
```

### Message Status Updates
```dart
// Update message status to delivered
await messageRef.update({
  'status': 'delivered',
  'delivered_at': FieldValue.serverTimestamp(),
});

// Mark as read
await messageRef.update({
  'status': 'read',
  'read_by.${userId}': FieldValue.serverTimestamp(),
});

// Reset unread count in conversation document
await conversationRef.update({
  'user_settings.$userId.unread_count': 0,
  'user_settings.$userId.last_read': FieldValue.serverTimestamp(),
});
```

### Query Examples for New Structure

1. **Get User's Conversations**
```dart
Stream<List<ConversationPreview>> getUserConversations(String userId) {
  return FirebaseFirestore.instance
    .collection(_universityPath)
    .doc('data')
    .collection('conversations')
    .where('participants', arrayContains: userId)
    .orderBy('updated_at', descending: true)
    .snapshots()
    .map((snapshot) {
      // User settings are already in the conversation document
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final userSettings = data['user_settings']?[userId] ?? {};
        
        return ConversationPreview(
          id: doc.id,
          lastMessage: data['last_message'],
          participants: data['participants'],
          participantDetails: data['participant_details'],
          // User-specific settings from the conversation doc
          unreadCount: userSettings['unread_count'] ?? 0,
          lastRead: userSettings['last_read'],
          archived: userSettings['archived'] ?? false,
          pinned: userSettings['pinned'] ?? false,
          muted: userSettings['notifications_enabled'] == false,
        );
      }).toList();
    });
}
```

2. **Get Messages with Pagination**
```dart
Query<Message> getMessagesQuery(String conversationId, {DocumentSnapshot? lastDoc}) {
  var query = FirebaseFirestore.instance
    .collection(_universityPath)
    .doc('data')
    .collection('conversations')
    .doc(conversationId)
    .collection('messages')
    .orderBy('sent_at', descending: true)
    .limit(50);
    
  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }
  
  return query;
}
```

### Media Message Handling
```dart
// For image/file messages
{
  'sender_id': 'Emerald_Nash',
  'type': 'image',
  'message': 'Shared an image',  // Fallback text
  'media': {
    'url': 'https://storage.url/image.jpg',
    'thumbnail_url': 'https://storage.url/thumb.jpg',
    'mime_type': 'image/jpeg',
    'size': 1024000,  // bytes
    'width': 1920,
    'height': 1080,
    'filename': 'meeting_notes.jpg'
  },
  'sent_at': serverTimestamp,
}
```

### Error Handling Considerations

1. **Network Failures**
   - Implement offline queue for messages
   - Show pending state in UI
   - Retry with exponential backoff

2. **Permission Errors**
   - Check if user is still participant
   - Handle removed/blocked users
   - Show appropriate error messages

3. **Migration Errors**
   - Log failed conversions
   - Skip and continue with next batch
   - Provide manual retry option

## Next Steps

1. Review and approve this plan
2. Update Cloud Functions:
   - Modify `initializeUniversity` to create `conversations` collection
   - Update `initializeUserSubcollections` to create `conversations` instead of `messages`
   - Create new conversation management functions
3. Create `MessageMigrationService` class
4. Update `MessagingService` with feature flags
5. Begin Phase 1 implementation

## Summary - Complete Implementation Checklist

### ✅ Database Structure
- [x] Current structure documented
- [x] New structure with all fields defined
- [x] Dynamic paths (no hardcoding)
- [x] Conversation ID format specified

### ✅ Cloud Functions
- [x] University initialization updates identified
- [x] User subcollection updates identified
- [x] New conversation creation function outlined
- [x] Path generation using existing utilities

### ✅ Security Rules
- [x] Complete rules for conversations collection
- [x] User conversation reference rules
- [x] Participant-based access control

### ✅ Implementation Details
- [x] Conversation creation logic
- [x] Message sending flow
- [x] Read receipts and status updates
- [x] Typing indicators structure
- [x] Unread count management
- [x] Media message format
- [x] Query examples

### ✅ Migration Strategy
- [x] Phased approach with safety nets
- [x] Dual-write capability
- [x] Rollback plan
- [x] Progress tracking

### ✅ Additional Features
- [x] Message reactions
- [x] Conversation settings (mute, archive, pin)
- [x] Error handling strategies
- [x] Offline queue considerations

This document now contains everything needed to implement a modern, scalable messaging system that:
- Supports real-time features (typing, read receipts, reactions)
- Works with the multi-tenant architecture
- Follows industry best practices
- Maintains backward compatibility during migration

## Complete File Checklist

### Backend Files to Modify:
- [ ] `/functions/src/university/initialization.ts` - Change 'messages' to 'conversations' in collectionsToCreate
- [ ] `/functions/src/utils/database.ts` - Remove 'messages' from initializeUserSubcollections
- [ ] `/functions/src/messaging/conversations.ts` - NEW file to create for conversation management

### Frontend Files to Modify:
- [ ] `/lib/services/direct_database_service.dart` - Change 'messages' to 'conversations' in collectionsToCreate
- [ ] `/lib/screens/web/shared/web_messaging/services/messaging_service.dart` - Update all message operations
- [ ] `/lib/screens/web/shared/web_messaging/web_messaging_screen.dart` - Update UI logic
- [ ] `/lib/screens/web/shared/web_messaging/models/conversation.dart` - Update model structure
- [ ] `/lib/models/message.dart` - Already updated for Timestamp handling ✓

### Excel Import Process:
- [ ] No changes needed - bulk import automatically uses Cloud Functions which will be updated

### Key Notes:
- NO hardcoded paths - all use CloudFunctionService.getCurrentUniversityPath()
- NO user conversations subcollection - all user settings stored in conversation document
- ALL initialization paths have been identified and documented