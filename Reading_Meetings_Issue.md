# Reading Meetings Issue - Progress and Findings

## Date: June 18, 2025

## Quick Summary
**Problem**: Mentor can create meetings with mentees, but the meetings don't show up on the calendar (only availability slots appear as dots).

**Root Cause**: Meeting subscription service is not properly retrieving meetings from the user subcollection in Firestore.

**Key Fix Applied**: Changed from using `firebase_uid` to document ID (e.g., "Dasarathi_Narayanan") since not all users have signed up yet.

## Overview
The meeting scheduler is successfully saving meetings to the database, but the saved meetings are not appearing on the calendar view. Only availability slots are showing up as dots on the calendar.

## What's Working ✅
1. **Meeting Creation**: Meetings are being saved successfully to Firestore
2. **Mentee Selection**: Fixed the issue where mentee_id was empty by:
   - Using document ID (e.g., "Dasarathi_Narayanan") as primary identifier instead of firebase_uid
   - Updated backend to handle both document IDs and firebase_uid lookups
3. **Calendar Dots**: The calendar is showing dots for availability slots (light blue for available times)
4. **Database Structure**: Meetings are correctly saved to user subcollections at paths like:
   - `/california_merced_uc_merced/data/users/Emerald_Nash/meetings/POjE8LsFEIuKokFS1OPS`

## What's Not Working ❌
1. **Meeting Display**: Scheduled meetings are not showing up on the calendar
2. **Real-time Updates**: The meeting subscription might not be working correctly
3. **ID Mismatch**: Frontend generates UUID but Firebase uses auto-generated IDs

## Code Changes Made

### 1. Fixed Mentee ID Selection (web_schedule_meeting_screen.dart)
```dart
// Changed from:
menteeId = _selectedMenteeOrMentor!['firebase_uid'] ?? _selectedMenteeOrMentor!['id'];

// To:
menteeId = _selectedMenteeOrMentor?['id'] ?? _selectedMenteeOrMentor?['firebase_uid'] ?? '';
```

### 2. Updated Backend User Lookups (meetings/management.ts)
```typescript
// Now tries document ID first, then falls back to firebase_uid
let menteeDocId: string | null = null;
try {
  const menteeDocById = await usersCollection.doc(mentee_id).get();
  if (menteeDocById.exists) {
    menteeDocId = menteeDocById.id;
  }
} catch (e) {
  // Document ID lookup failed, try firebase_uid
}

if (!menteeDocId) {
  const menteeQuery = await usersCollection.where('firebase_uid', '==', mentee_id).limit(1).get();
  if (!menteeQuery.empty) {
    menteeDocId = menteeQuery.docs[0].id;
  }
}
```

### 3. Fixed Availability Slot Booking
- Implemented the missing functionality to mark availability slots as booked when meetings are created
- Updates both main availability collection and user subcollection

### 4. Added Meeting Display Section
- Added a visual display of events for the selected day
- Shows availability slots and meetings with appropriate icons and colors
- Fixed UI overflow issue by changing from `Expanded` to `Flexible` widget

## Debug Findings

### Calendar Event Loading
```
DEBUG: eventLoader called with day: 2025-06-20 00:00:00.000Z
DEBUG: Found 3 events for 2025-06-20 00:00:00.000
  - Event: 12:00 PM (Available)
  - Event: 2:30 PM (Available)
  - Event: 4:00 PM (Available)
```
- Calendar is successfully loading availability slots
- But NO meetings are appearing in the events

### Meeting Stream Subscription
The issue appears to be that the meeting subscription is not retrieving meetings from the user subcollection. Enhanced debugging was added to track:
- Subscription path
- Number of documents found
- Meeting data structure

### Debug Code Added
1. **eventLoader debugging** (web_schedule_meeting_screen.dart):
   - Shows what day format TableCalendar is using
   - Logs events found for each day

2. **markerBuilder debugging** (web_schedule_meeting_screen.dart):
   - Confirms dots are being rendered
   - Shows event count per day

3. **Meeting subscription debugging** (meeting_service.dart):
   - Logs subscription path
   - Shows meeting document data
   - Tracks stream updates

4. **Build calendar events debugging** (web_schedule_meeting_screen.dart):
   - Shows meeting count and details
   - Logs date key format issues

## Identified Issues

### 1. Meeting ID Inconsistency
- Frontend generates: `_uuid.v4()` (e.g., "550e8400-e29b-41d4-a716-446655440000")
- Firebase stores: Auto-generated ID (e.g., "POjE8LsFEIuKokFS1OPS")
- This mismatch could cause reference issues

### 2. Potential Subscription Path Issue
- Meetings are stored at: `/users/Emerald_Nash/meetings/`
- Need to verify the subscription is looking at the correct path
- The subscription uses firebase_uid to find the user document, which might fail for users without firebase_uid

### 3. Meeting Data Structure
Need to verify that the meeting data structure in Firestore matches what the Meeting model expects:
- `mentor_id`
- `mentee_id`
- `start_time`
- `end_time`
- `topic`
- `location`
- `status`
- `availability_id`

## Next Steps

1. **Fix ID Consistency**: 
   - Modify backend to use the frontend-provided UUID as document ID
   - Update createDocument to accept custom IDs

2. **Debug Subscription Path**:
   - Add logging to see the exact path being subscribed to
   - Verify meetings exist at that path in Firestore console

3. **Check Data Structure**:
   - Log the raw meeting data from Firestore
   - Ensure field names match exactly

4. **Test Alternative Subscription**:
   - Try subscribing to the main meetings collection as a fallback
   - Consider using a query that checks both mentor_id and mentee_id

## Mobile App Reference
The mobile app successfully displays meetings using:
- Local database instead of Firestore
- `calendar_view` package with custom `cellBuilder`
- `_buildCalendarEvents()` method that processes both availability and meetings

The web version uses:
- `table_calendar` package with `eventLoader` and `markerBuilder`
- Same `_buildCalendarEvents()` logic but meetings aren't being loaded from Firestore

## Technical Details

### Frontend Files Modified:
- `/lib/screens/web_schedule_meeting_screen.dart`
- `/lib/services/meeting_service.dart`

### Backend Files Modified:
- `/functions/src/meetings/management.ts`

### Database Structure:
```
/california_merced_uc_merced/
  /data/
    /users/
      /{user_document_id}/          # e.g., "Emerald_Nash"
        /meetings/
          /{meeting_id}/            # e.g., "POjE8LsFEIuKokFS1OPS"
        /availability/
          /{availability_doc_id}/   # e.g., "Emerald_Nash_2025-06-20"
    /meetings/                      # Main meetings collection
      /{meeting_id}/
```

## Important Notes
1. **TypeScript Changes**: After modifying any TypeScript files in `/functions/src/`, you need to run `npm run build` in the functions directory to compile the changes.

2. **User IDs**: Not all users have `firebase_uid` since they haven't signed up yet. Always use document ID as primary identifier.

3. **Testing**: When testing, check the Firestore console to verify:
   - Meetings are saved to the correct path
   - Data structure matches expected format
   - User document IDs are correct

## Fixed! (June 18, 2025)

### Issue Resolution
The backend was working correctly all along! The issues were:

1. **UI Overflow Error**: The Row widget displaying events didn't have proper flex constraints
   - Fixed by wrapping event display elements with Expanded/Flexible widgets
   
2. **Metadata Document**: The meeting subscription was including `_metadata` documents
   - Fixed by filtering out documents starting with underscore
   
3. **Availability Status**: Availability slots weren't showing as "Booked" when meetings existed
   - Fixed by cross-referencing meetings with availability slots during calendar event building

### Future Optimization
To reduce Firestore reads, implement date-based filtering in meeting subscriptions:
```dart
// Instead of subscribing to ALL meetings
collection.snapshots()

// Subscribe only to recent/upcoming meetings
collection
  .where('start_time', isGreaterThan: DateTime.now().subtract(Duration(days: 30)))
  .where('start_time', isLessThan: DateTime.now().add(Duration(days: 90)))
  .orderBy('start_time')
  .snapshots()
```

## Conclusion
Meetings are now successfully displayed on the calendar! The subscription service correctly retrieves meetings from user subcollections, and the UI properly renders them without overflow errors.