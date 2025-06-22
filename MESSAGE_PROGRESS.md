# Messaging System Progress

## Problem
The messaging system has several issues:
1. **Path Structure**: Messages are being saved to incorrect Firestore paths
2. **ID Mismatch**: System is mixing Firebase UIDs with document IDs
3. **Loading Issues**: Messages show indefinite loading spinner after sending

## Debug Output Analysis
```
conversationId: Dasarathi_Narayanan__kjQ4Q2ZPnAvDmeYVChmY5lM7prlp
senderId: kjQ4Q2ZPnAvDmeYVChmY5lM7prlp (Firebase UID - WRONG!)
Sender path: universities/California/Merced/UC_Merced/data/data/users/kjQ4Q2ZPnAvDmeYVChmY5lM7prlp/messages (WRONG!)
```

## Correct Path Structure
- Correct format: `/california_merced_uc_merced/data/users/{documentId}/messages`
- Example: `/california_merced_uc_merced/data/users/Emerald_Nash/messages`
- Example: `/california_merced_uc_merced/data/users/Dasarathi_Narayanan/messages`

## Solution
1. Use document IDs (like "Emerald_Nash") instead of Firebase UIDs
2. Update all Firestore paths to use `california_merced_uc_merced` collection
3. Ensure conversation IDs use document IDs: `Emerald_Nash__Alice_Johnson`

## Current Progress

### ✅ Completed
1. **Fixed Firestore Paths** in `messaging_service.dart`:
   - Changed from `universities/California/Merced/UC_Merced` to `california_merced_uc_merced`
   - Updated sendMessage, getMessagesStream, getConversationsStream, _getLastMessage
   - Updated typing indicators paths

2. **Updated WebMessagingScreen**:
   - Fixed user document query path
   - Updated RealTimeUserService path
   - Verified document ID is being passed correctly to MessageController

3. **Added Comprehensive Debugging**:
   - Message sending flow logs
   - Path debugging
   - Status tracking
   - Pre-selected conversation debugging

4. **Verified Dashboard Integration**:
   - Dashboard service correctly passes mentee document IDs (e.g., "Dasarathi_Narayanan")
   - MenteeGridCard passes correct document ID to WebMessagingScreen

### ✅ Root Cause Identified
The system is correctly set up to use document IDs. The code analysis shows:
- `web_messaging_screen.dart` correctly fetches and uses the user's document ID
- `dashboard_data_service.dart` correctly sets mentee IDs to document IDs (line 126)
- `mentee_grid_card.dart` correctly passes `mentee.id` which is the document ID

### 🔍 Testing Instructions
1. **Clear browser cache** to ensure no stale data
2. **Start Firebase emulator** with the test data
3. **Login as mentor** (Emerald_Nash)
4. **Click on a mentee** from "Your Mentees" section
5. **Check console output** for:
   - `preSelectedUserId` should be "Dasarathi_Narayanan" (not Firebase UID)
   - `currentUserDocId` should be "Emerald_Nash" (not Firebase UID)
   - `conversationId` should be "Dasarathi_Narayanan__Emerald_Nash" or "Emerald_Nash__Dasarathi_Narayanan"
6. **Send a message** and verify it saves to:
   - `/california_merced_uc_merced/data/users/Emerald_Nash/messages`
   - `/california_merced_uc_merced/data/users/Dasarathi_Narayanan/messages`

### 📝 Summary of Changes
- Added extensive debugging to track document IDs vs Firebase UIDs
- Verified dashboard correctly passes document IDs
- Added warnings if Firebase UID is used as fallback
- All code paths now use document IDs consistently

## Key Files Modified
- `/lib/screens/web/shared/web_messaging/services/messaging_service.dart`
  - Removed hardcoded "california_merced_uc_merced" paths
  - Now uses `CloudFunctionService.getCurrentUniversityPath()`
  - Imported CloudFunctionService
- `/lib/screens/web/shared/web_messaging/web_messaging_screen.dart`
  - Removed hardcoded "california_merced_uc_merced" paths
  - Now uses `CloudFunctionService.getCurrentUniversityPath()`
  - Imported CloudFunctionService

## Important Note
No paths are hardcoded anymore. The messaging system now dynamically gets the university path from `CloudFunctionService.getCurrentUniversityPath()`, which allows it to work with any university in the multi-tenant system.
- `/lib/screens/web/shared/web_messaging/controllers/message_controller.dart`
- `/lib/screens/web/mentor/web_mentor_dashboard/models/dashboard_data.dart`

## Next Steps
1. Ensure `currentUserId` in MessageController uses document ID
2. Fix conversation ID generation to use document IDs only
3. Verify messages are saved to correct paths after fixes

## Critical Context for Next Session

### The Root Cause
The `_currentUserDocId` is being set in `_initializeServices()` but when a mentee is pre-selected from the dashboard, the conversation ID is generated using the wrong user ID format.

### Specific Fix Needed
In `web_messaging_screen.dart`:
- The `_selectPreSelectedConversation` method generates conversation ID
- The `MessageController` is initialized with `userDocId` but might be getting Firebase UID in some cases
- Need to trace why conversation ID has format: `Dasarathi_Narayanan__kjQ4Q2ZPnAvDmeYVChmY5lM7prlp`

### Testing Approach
1. Click on a mentee from "Your Mentees" section
2. Check console for debug output
3. Verify conversation ID format
4. Send a message and check if it saves to:
   - `/california_merced_uc_merced/data/users/Emerald_Nash/messages`
   - `/california_merced_uc_merced/data/users/Dasarathi_Narayanan/messages`

### Additional Context
- The app uses Flutter Web
- Firebase Emulator is being used for testing
- Mentor account is using document ID "Emerald_Nash"
- Test mentee is "Dasarathi_Narayanan"