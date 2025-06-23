# Message Database Migration Status - January 2025

## Overview
Migration from user-centric message storage to conversation-centric structure is **IN PROGRESS** with critical issues identified and resolved.

## Current Status: 🟡 PARTIALLY WORKING

### ✅ Completed Items

#### 1. Backend Structure Updates
- **University Initialization** - Updated to create 'conversations' collection
- **User Subcollections** - Removed 'messages' from user subcollections
- **Cloud Functions** - All conversation management functions created:
  - `createChatConversation`
  - `sendChatMessage`
  - `markChatMessagesRead`
  - `updateChatSettings`
  - `getUserChatConversations`

#### 2. Frontend Implementation
- **Web UI Updated** - Now uses MessagingServiceV2
- **Services Created**:
  - ConversationService (core functionality)
  - MessagingServiceV2 (UI compatibility wrapper)
  - MessageMigrationService (for data migration)
- **Messages NOW write to conversations collection** ✅

#### 3. Critical Fixes Applied
- **Fixed Cloud Functions validation** - Now properly checks Firebase UIDs against `firebase_uid` field in user documents
- **Fixed operator precedence error** in conversation_v2.dart
- **Added missing conversation methods** to CloudFunctionService
- **Updated all controllers** to use MessagingServiceV2

### 🔧 Issues Discovered & Fixed

#### 1. Firebase UID vs Document ID Mismatch
**Problem**: Cloud Functions were comparing Firebase Auth UIDs with Firestore document IDs
- Document IDs: "FirstName_LastName" format (e.g., "Emerald_Nash")
- Firebase UIDs: Random strings (e.g., "yzktH7dEvItgzrdc1Xb52dDREYTL")

**Solution**: Updated all Cloud Functions to:
1. Look up user documents by document ID
2. Check the `firebase_uid` field for authentication validation
3. Use document IDs for all data operations

#### 2. Missing Custom Claims
**Problem**: 500 Internal Server Error when creating conversations
- Users missing `university_path` custom claim in Firebase Auth
- Functions defaulting to empty string, creating invalid Firestore paths

**Current Issue**: Need to ensure users have proper custom claims:
- `role`: User's role (mentor, mentee, coordinator)
- `university_path`: University identifier (e.g., "california_merced_uc_merced")

### 🚧 Remaining Issues

1. **Custom Claims Not Set**
   - Users need to have `university_path` set in their Firebase Auth custom claims
   - Without this, conversation creation fails with 500 error
   - Need to call `syncClaimsOnLogin` after user authentication

2. **User Document Requirements**
   - User documents must have `firebase_uid` field populated
   - This happens on first login or registration
   - Bulk imported users may not have this field until they log in

## Testing Results

### What Works ✅
- Messages are written to `/conversations/{conversationId}/messages/` 
- No longer writing to user subcollections
- UI properly uses new conversation-centric structure
- TypeScript compilation passes without errors

### What Fails ❌
- Creating conversations fails if user lacks custom claims
- 500 error: "Failed to create conversation" due to missing `university_path`

## Required Actions

### Immediate
1. **Ensure Custom Claims**: Make sure `syncClaimsOnLogin` is called after authentication
2. **Add Fallback**: Consider hardcoding `university_path` temporarily since only one university exists
3. **Validate User Data**: Ensure all users have `firebase_uid` field populated

### Before Production
1. Deploy updated Cloud Functions
2. Test with users who have proper custom claims
3. Run migration service on existing messages
4. Update Firestore security rules

## Code Changes Summary

### Modified Files
- `/lib/screens/web/shared/web_messaging/web_messaging_screen.dart` - Uses MessagingServiceV2
- `/lib/screens/web/shared/web_messaging/controllers/*.dart` - Updated to use MessagingServiceV2
- `/lib/services/cloud_function_service.dart` - Added conversation methods
- `/lib/models/conversation_v2.dart` - Fixed operator precedence
- `/functions/src/messaging/conversations.ts` - Fixed UID validation

### Key Change
Messages now flow through:
```
UI → MessagingServiceV2 → ConversationService → Cloud Functions → /conversations collection
```

Instead of the old flow:
```
UI → MessagingService → /users/{userId}/messages subcollection
```

## Success Metrics
- ✅ No more duplicate message storage
- ✅ Messages stored in conversations collection
- ✅ Proper participant validation (when custom claims are set)
- ⏳ Real-time features ready (pending full deployment)
- ⏳ 50% storage reduction (after migration)

## Next Steps
1. Fix custom claims initialization
2. Test with properly authenticated users
3. Deploy to production
4. Run migration service
5. Monitor performance

---
*Last Updated: January 2025*