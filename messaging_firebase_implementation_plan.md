# Messaging System Firebase Implementation Plan

## Overview
This document outlines the plan for migrating the current local SQLite-based messaging system to Firebase Firestore while maintaining offline functionality and ensuring a smooth transition.

## Current Architecture Summary
- **Local Storage**: SQLite with messages and message_visibility tables
- **Service Layer**: MessagingService with ChangeNotifier pattern
- **Chat ID Format**: `mentorId__menteeId`
- **Features**: Message visibility per user, test mode support, real-time UI updates

## Implementation Phases

### Phase 1: Repository Pattern Implementation
**Goal**: Create abstraction layer to decouple business logic from data source

#### Tasks:
1. Create `MessageRepository` interface
```dart
abstract class MessageRepository {
  Future<List<Message>> getMessagesByChat(String chatId);
  Future<List<Message>> getVisibleMessagesByChat(String chatId, String userId);
  Future<bool> createMessage(Message message);
  Future<void> hideMessagesForUser(String chatId, String userId);
  Future<void> deleteMessage(String messageId);
}
```

2. Implement `LocalMessageRepository` (current SQLite implementation)
3. Update `MessagingService` to use repository interface
4. Ensure all existing functionality works unchanged

### Phase 2: Firebase Integration
**Goal**: Add Firebase Firestore support alongside local storage

#### Tasks:
1. Create `FirebaseMessageRepository` implementing the interface
2. Set up Firestore collections structure:
```
messages/
  {chatId}/
    messages/
      {messageId}/
        - id: String
        - senderId: String
        - message: String
        - timestamp: FieldValue.serverTimestamp()
        - syncedToLocal: Boolean
        
messageVisibility/
  {userId}/
    hiddenMessages/
      {messageId}: timestamp
```

3. Implement `HybridMessageRepository` that:
   - Writes to both local and Firebase
   - Reads from local first (offline-first)
   - Syncs in background

### Phase 3: Sync Mechanism
**Goal**: Reliable offline-first messaging with background sync

#### Features to Implement:
1. **Offline Queue**
   - Track unsent messages locally
   - Retry sending when connection restored
   - Handle conflicts and duplicates

2. **Sync Status Tracking**
   ```dart
   enum MessageStatus {
     pending,    // Created locally, not sent
     sent,       // Sent to Firebase
     delivered,  // Confirmed in Firebase
     read,       // Read by recipient
     failed      // Send failed
   }
   ```

3. **Background Sync Service**
   - Sync local messages to Firebase when online
   - Pull new messages from Firebase
   - Update sync status in local DB

### Phase 4: Real-time Features
**Goal**: Add Firebase real-time capabilities

#### Implementation:
1. **Real-time Listeners**
   ```dart
   Stream<List<Message>> watchMessages(String chatId) {
     return FirebaseFirestore.instance
         .collection('messages')
         .doc(chatId)
         .collection('messages')
         .orderBy('timestamp', descending: true)
         .snapshots()
         .map((snapshot) => /* convert to Message objects */);
   }
   ```

2. **Presence System**
   - Track online/offline status
   - Show "typing" indicators
   - Last seen timestamps

3. **Read Receipts**
   - Track when messages are read
   - Update UI with read status
   - Batch updates for efficiency

### Phase 5: Migration & Deployment
**Goal**: Seamless transition for existing users

#### Steps:
1. **Data Migration Strategy**
   - Export existing local messages
   - Batch upload to Firebase
   - Verify data integrity
   - Keep local copies as backup

2. **Feature Flags**
   ```dart
   class FeatureFlags {
     static bool useFirebaseMessaging = false;
     static bool enableRealTimeSync = false;
     static bool showReadReceipts = false;
   }
   ```

3. **Gradual Rollout**
   - Enable for test users first
   - Monitor performance and errors
   - Roll out to all users
   - Keep fallback to local-only mode

## Technical Considerations

### 1. Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own chats
    match /messages/{chatId}/messages/{messageId} {
      allow read: if request.auth.uid in chatId.split('__');
      allow create: if request.auth.uid == resource.data.senderId
                    && request.auth.uid in chatId.split('__');
    }
  }
}
```

### 2. Performance Optimization
- Implement pagination (load 50 messages at a time)
- Use Firestore compound queries for efficient filtering
- Cache frequently accessed data
- Optimize image/file uploads with Firebase Storage

### 3. Error Handling
- Network failure recovery
- Conflict resolution for concurrent edits
- Data validation at both client and server
- Graceful degradation to offline mode

### 4. Push Notifications
- Integrate Firebase Cloud Messaging (FCM)
- Send notification on new message
- Handle notification taps to open correct chat
- Respect user notification preferences

## Testing Strategy

### 1. Unit Tests
- Repository implementations
- Sync logic
- Message status transitions

### 2. Integration Tests
- Local-to-Firebase sync
- Offline/online transitions
- Real-time updates

### 3. E2E Tests
- Complete message flow
- Multi-device scenarios
- Network interruption handling

## Monitoring & Analytics

### 1. Performance Metrics
- Message delivery time
- Sync success rate
- Offline duration tracking
- Firebase usage costs

### 2. Error Tracking
- Failed message sends
- Sync conflicts
- Authentication issues
- Network timeouts

## Timeline Estimate

- Phase 1: 1 week (Repository pattern)
- Phase 2: 2 weeks (Firebase integration)
- Phase 3: 2 weeks (Sync mechanism)
- Phase 4: 1 week (Real-time features)
- Phase 5: 1 week (Migration & deployment)
- Testing & refinement: 1 week

**Total: 8 weeks**

## Success Criteria

1. ✅ All existing features work with Firebase backend
2. ✅ Messages sync reliably between devices
3. ✅ Offline functionality maintained
4. ✅ Real-time updates working
5. ✅ No data loss during migration
6. ✅ Performance equal or better than current system
7. ✅ Cost-effective Firebase usage

## Future Enhancements

- End-to-end encryption
- Voice/video calling
- File and image sharing
- Message reactions and replies
- Group chat support
- Message search functionality
- Chat export features