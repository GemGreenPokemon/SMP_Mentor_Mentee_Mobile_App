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
        │   ├── [existing user profile data]
        │   │
        │   └── conversations/ (lightweight references)
        │       └── {conversationId}/
        │           ├── conversation_ref: "/conversations/Dasarathi_Narayanan__Emerald_Nash"
        │           ├── unread_count: 0
        │           ├── last_read: timestamp
        │           ├── notifications_enabled: true
        │           ├── archived: false
        │           ├── pinned: false
        │           └── custom_nickname: "Dasarathi - Mentee"  // Optional
        │
        └── {userDocId2}/  (e.g., "Dasarathi_Narayanan")
            └── conversations/
                └── {conversationId}/
                    └── [similar lightweight reference]
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

// User conversation references
match /users/{userId}/conversations/{conversationId} {
  allow read, write: if request.auth.uid == userId;
}
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

## Next Steps

1. Review and approve this plan
2. Create `MessageMigrationService` class
3. Update `MessagingService` with feature flags
4. Begin Phase 1 implementation