# Meetings and Availability Database Restructure Plan

## Table of Contents
1. [Current Problematic Structure](#current-problematic-structure)
2. [New Proposed Structure](#new-proposed-structure)
3. [Benefits of the New Structure](#benefits-of-the-new-structure)
4. [Migration Strategy](#migration-strategy)
5. [Implementation Details](#implementation-details)

## Current Problematic Structure

### Issues Identified

#### 1. **Subcollection Complexity**
- Meetings stored in THREE places:
  - `/{universityPath}/data/meetings/{meetingId}` (primary)
  - `/{universityPath}/data/users/{userId}/meetings/{meetingId}` (mentor copy)
  - `/{universityPath}/data/users/{userId}/meetings/{meetingId}` (mentee copy)
- Availability stored in TWO places:
  - `/{universityPath}/data/availability/{availabilityId}` (primary)
  - `/{universityPath}/data/users/{userId}/availability/{availabilityId}` (user copy)

#### 2. **Redundant Data Storage**
- Same meeting data duplicated across multiple locations
- Synchronization issues when updating meetings
- Increased Firestore read/write costs
- Complex batch operations required for consistency

#### 3. **User Reference Confusion**
- Inconsistent user identification:
  - Sometimes uses Firebase UID (e.g., `Qq4dMqGW8kVH7bQKT4MWNdPUFGm2`)
  - Sometimes uses document ID (e.g., `Emerald_Nash`)
  - Complex lookup logic to translate between the two

#### 4. **Query Limitations**
- Cannot easily query all meetings across users
- Cannot efficiently filter meetings by date range
- Subcollection queries don't support cross-user searches
- Complex aggregation for reporting

#### 5. **Security Rule Complexity**
- Difficult to maintain consistent permissions across duplicated data
- Subcollection rules are harder to manage
- Performance impact from complex rule evaluations

## New Proposed Structure

### Top-Level Collections Only

#### 1. **Meetings Collection**
```
/{universityPath}/data/meetings/{meetingId}
```

**Meeting ID Format:**
```javascript
// Format: {mentorDocId}__{menteeDocId}__{timestamp}
// Example: "Dasarathi_Narayanan__Emerald_Nash__1704835200"
// Uses the same name-based IDs as conversations for consistency
// This makes meetings instantly identifiable and sortable by participants and time
```

**Document Structure:**
```javascript
{
  id: string,                    // Human-readable: "mentorDocId__menteeDocId__timestamp"
  mentor_doc_id: string,         // User document ID (e.g., "Dasarathi_Narayanan")
  mentee_doc_id: string,         // User document ID (e.g., "Emerald_Nash")
  mentor_uid: string,            // Firebase UID of mentor
  mentee_uid: string,            // Firebase UID of mentee
  mentor_name: string,           // Denormalized for display
  mentee_name: string,           // Denormalized for display
  start_time: timestamp,         // Firestore timestamp
  end_time: timestamp,           // Firestore timestamp
  topic: string,
  location: string,
  status: string,                // 'pending' | 'accepted' | 'rejected' | 'cancelled'
  availability_id: string,  // Reference to availability slot if booked
  
  // Metadata
  created_at: timestamp,
  created_by: string,            // Firebase UID
  updated_at: timestamp,
  updated_by: string,            // Firebase UID
  
  // Status tracking
  accepted_at: timestamp,
  accepted_by: string,
  rejected_at: timestamp,
  rejected_by: string,
  rejection_reason: string,
  cancelled_at: timestamp,
  cancelled_by: string,
  cancellation_reason: string
}
```

#### 2. **Availability Collection**
```
/{universityPath}/data/availability/{availabilityId}
```

**Document Structure:**
```javascript
{
  id: string,                    // Auto-generated availability ID
  mentor_uid: string,            // Firebase UID of mentor
  mentor_name: string,           // Denormalized for display
  date: timestamp,               // Date of availability (normalized to start of day)
  day_of_week: string,           // 'monday' | 'tuesday' | etc.
  
  // Individual time slot
  start_time: string,            // "14:00"
  end_time: string,              // "15:00"
  
  // Booking status
  is_booked: boolean,
  booked_by_uid: string,         // Firebase UID of mentee who booked
  booked_by_name: string,        // Denormalized for display
  meeting_id: string,            // Reference to meeting if booked
  
  // Metadata
  created_at: timestamp,
  updated_at: timestamp,
  
  // Composite fields for efficient querying
  mentor_date: string,           // "mentorUid_2025-01-15" for compound queries
  week_number: number,           // ISO week number for weekly views
  month_year: string             // "2025-01" for monthly views
}
```

### Eliminated Collections/Subcollections
- ❌ `/users/{userId}/meetings` subcollection
- ❌ `/users/{userId}/availability` subcollection
- ❌ `/users/{userId}/requestedMeetings` subcollection

## Benefits of the New Structure

### 1. **Simplified Data Management**
- Single source of truth for each entity
- No data duplication or synchronization issues
- Reduced Firestore operations and costs
- Simpler update logic
- Human-readable meeting IDs for easier debugging

### 2. **Improved Query Capabilities**
- Easy cross-user queries (e.g., all meetings for a coordinator)
- Efficient date range filtering
- Better support for reporting and analytics
- Can use compound indexes for complex queries

### 3. **Standardized User References**
- Always use Firebase UID for user references
- Consistent identification across all collections
- Denormalized display names for UI convenience
- No complex user lookup logic

### 4. **Better Performance**
- Fewer reads/writes per operation
- More efficient real-time listeners
- Optimized index usage
- Reduced client-side processing

### 5. **Simplified Security Rules**
- Clearer permission boundaries
- Easier to audit and maintain
- Better performance due to simpler rules
- Consistent access patterns

## Migration Strategy

### Phase 1: Preparation
1. **Backup Current Data**
   - Export all meeting and availability data
   - Document current relationships
   - Create rollback plan

2. **Update Cloud Functions**
   - Modify functions to support both structures temporarily
   - Add migration flags to control behavior
   - Implement data transformation logic

### Phase 2: Data Migration
1. **Create Migration Script**
   ```typescript
   // Pseudo-code for migration
   async function migrateMeetings() {
     // 1. Read all meetings from primary collection
     // 2. Transform to new structure
     // 3. Write to new collection with standardized UIDs
     // 4. Verify data integrity
   }
   
   async function migrateAvailability() {
     // 1. Read all availability from both locations
     // 2. Flatten nested slot arrays into individual documents
     // 3. Add composite fields for querying
     // 4. Write to new collection
   }
   ```

2. **Run Migration in Batches**
   - Process in small batches to avoid timeouts
   - Log all operations for audit trail
   - Validate data after each batch

### Phase 3: Update Application Code
1. **Update Service Layer**
   - Modify `MeetingService` to use new structure
   - Remove subcollection operations
   - Update query logic

2. **Update UI Components**
   - Adjust data models if needed
   - Update display logic for denormalized fields
   - Test all user flows

### Phase 4: Cleanup
1. **Remove Old Data**
   - Delete subcollections after verification
   - Archive backup data
   - Update documentation

2. **Update Security Rules**
   - Remove subcollection rules
   - Optimize for new structure
   - Test all permission scenarios

## Implementation Details

### New Collection Schemas

#### Meetings Collection Indexes
```
// Compound indexes needed:
1. mentor_uid + start_time (ascending)
2. mentee_uid + start_time (ascending)
3. status + start_time (ascending)
4. mentor_uid + mentee_uid + start_time
5. start_time (ascending) - for date range queries
```

#### Availability Collection Indexes
```
// Compound indexes needed:
1. mentor_uid + date (ascending)
2. mentor_uid + is_booked + date
3. mentor_date (ascending) - for efficient mentor+date queries
4. week_number + mentor_uid
5. month_year + mentor_uid
```

### Query Patterns

#### 1. Get meetings for a user (mentor or mentee)
```javascript
// For mentor
const mentorMeetings = await firestore
  .collection(`${universityPath}/data/meetings`)
  .where('mentor_uid', '==', userUid)
  .where('start_time', '>=', startDate)
  .where('start_time', '<=', endDate)
  .orderBy('start_time', 'asc')
  .get();

// For mentee
const menteeMeetings = await firestore
  .collection(`${universityPath}/data/meetings`)
  .where('mentee_uid', '==', userUid)
  .where('start_time', '>=', startDate)
  .where('start_time', '<=', endDate)
  .orderBy('start_time', 'asc')
  .get();
```

#### 2. Get available slots for a mentor
```javascript
const availableSlots = await firestore
  .collection(`${universityPath}/data/availability`)
  .where('mentor_uid', '==', mentorUid)
  .where('is_booked', '==', false)
  .where('date', '>=', startDate)
  .where('date', '<=', endDate)
  .orderBy('date', 'asc')
  .orderBy('start_time', 'asc')
  .get();
```

#### 4. Get all meetings between a mentor-mentee pair
```javascript
// Using the human-readable ID pattern for efficient queries
// Example: All meetings between Dasarathi_Narayanan and Emerald_Nash
const pairMeetings = await firestore
  .collection(`${universityPath}/data/meetings`)
  .where(firebase.firestore.FieldPath.documentId(), '>=', `${mentorDocId}__${menteeDocId}__`)
  .where(firebase.firestore.FieldPath.documentId(), '<', `${mentorDocId}__${menteeDocId}__~`)
  .orderBy(firebase.firestore.FieldPath.documentId())
  .get();
```

#### 3. Get all meetings for reporting (coordinator view)
```javascript
const allMeetings = await firestore
  .collection(`${universityPath}/data/meetings`)
  .where('start_time', '>=', reportStartDate)
  .where('start_time', '<=', reportEndDate)
  .orderBy('start_time', 'asc')
  .get();
```

### Security Rules Updates

```javascript
// Meetings collection
match /meetings/{meetingId} {
  // Read: User must be authenticated and in university
  allow read: if isInUniversity(universityPath);
  
  // Create: Must be mentor, mentee, or coordinator
  allow create: if isInUniversity(universityPath) && (
    request.auth.uid == request.resource.data.mentor_uid ||
    request.auth.uid == request.resource.data.mentee_uid ||
    hasRole('coordinator')
  );
  
  // Update: Only participants or coordinator
  allow update: if isInUniversity(universityPath) && (
    request.auth.uid == resource.data.mentor_uid ||
    request.auth.uid == resource.data.mentee_uid ||
    hasRole('coordinator')
  );
  
  // Delete: Only coordinator (soft delete preferred)
  allow delete: if isInUniversity(universityPath) && hasRole('coordinator');
}

// Availability collection
match /availability/{availabilityId} {
  // Read: Anyone in university can view availability
  allow read: if isInUniversity(universityPath);
  
  // Create: Only mentors can create their own availability
  allow create: if isInUniversity(universityPath) && 
    hasRole('mentor') &&
    request.auth.uid == request.resource.data.mentor_uid;
  
  // Update: Mentor owns it, or mentee booking it
  allow update: if isInUniversity(universityPath) && (
    (request.auth.uid == resource.data.mentor_uid) ||
    (hasRole('mentee') && !resource.data.is_booked && request.resource.data.is_booked)
  );
  
  // Delete: Only mentor can delete their own availability
  allow delete: if isInUniversity(universityPath) && 
    request.auth.uid == resource.data.mentor_uid &&
    !resource.data.is_booked;
}
```

### Service Layer Changes

#### MeetingService Updates
```typescript
class MeetingService {
  // Simplified meeting creation with human-readable ID
  async createMeeting(meeting: Meeting): Promise<Meeting> {
    // First, get the user document IDs from Firebase UIDs
    const mentorDoc = await this.getUserDocIdFromUid(meeting.mentorId);
    const menteeDoc = await this.getUserDocIdFromUid(meeting.menteeId);
    
    // Generate human-readable meeting ID using document IDs
    const timestamp = Math.floor(meeting.start_time.getTime() / 1000);
    const meetingId = `${mentorDoc.id}__${menteeDoc.id}__${timestamp}`;
    
    const meetingData = {
      ...meeting,
      id: meetingId,
      mentor_doc_id: mentorDoc.id,   // e.g., "Dasarathi_Narayanan"
      mentee_doc_id: menteeDoc.id,   // e.g., "Emerald_Nash"
      mentor_uid: meeting.mentorId,   // Firebase UID
      mentee_uid: meeting.menteeId,   // Firebase UID
      mentor_name: mentorDoc.name,    // Denormalized
      mentee_name: menteeDoc.name,    // Denormalized
      created_at: serverTimestamp(),
      created_by: this.currentUser.uid
    };
    
    // Use set() with custom ID instead of add()
    await firestore
      .collection(`${this.universityPath}/data/meetings`)
      .doc(meetingId)
      .set(meetingData);
    
    return { id: meetingId, ...meetingData };
  }
  
  // Simplified availability query
  async getAvailability(mentorUid: string, startDate: Date, endDate: Date) {
    return firestore
      .collection(`${this.universityPath}/data/availability`)
      .where('mentor_uid', '==', mentorUid)
      .where('date', '>=', startDate)
      .where('date', '<=', endDate)
      .orderBy('date', 'asc')
      .orderBy('start_time', 'asc')
      .get();
  }
}
```

### Data Consistency Helpers

```typescript
// Helper to maintain denormalized data
async function updateUserDisplayNames(userId: string, newName: string) {
  const batch = firestore.batch();
  
  // Update meetings where user is mentor
  const mentorMeetings = await firestore
    .collection(`${universityPath}/data/meetings`)
    .where('mentor_uid', '==', userId)
    .get();
  
  mentorMeetings.forEach(doc => {
    batch.update(doc.ref, { mentor_name: newName });
  });
  
  // Update meetings where user is mentee
  const menteeMeetings = await firestore
    .collection(`${universityPath}/data/meetings`)
    .where('mentee_uid', '==', userId)
    .get();
  
  menteeMeetings.forEach(doc => {
    batch.update(doc.ref, { mentee_name: newName });
  });
  
  // Similar updates for availability collection
  
  await batch.commit();
}
```

## File Modification Guide

### Files That Must Be Modified

#### 1. **Primary Service Layer (Dart/Flutter)**

##### `/lib/services/meeting_service.dart`
**Current Implementation:**
- Reads from: `users/{userId}/meetings` and `users/{userId}/availability`
- Methods to update:
  ```dart
  // Current subcollection queries
  subscribeToMeetings(String userId)
  subscribeToAvailability(String mentorId)
  getMeetingsByMentor(String mentorId)
  getMeetingsByMentee(String menteeId)
  getAvailabilityByMentor(String mentorId)
  ```

**New Implementation:**
- Read from: `/{universityPath}/data/meetings` and `/{universityPath}/data/availability`
- Add helper method to get user doc ID from Firebase UID
- Update all queries to use top-level collections with UID filters

#### 2. **Cloud Functions (TypeScript)**

##### `/functions/src/meetings/management.ts`
**Current Implementation:**
- Writes to BOTH university collection AND user subcollections
- Functions to modify:
  ```typescript
  createMeeting() // Remove subcollection writes
  updateMeeting() // Remove subcollection updates
  cancelMeeting() // Remove subcollection updates
  setMentorAvailability() // Remove subcollection writes
  getMentorAvailability() // Query top-level only
  getAvailableSlots() // Query top-level only
  ```

##### `/functions/src/utils/database.ts`
**Current Implementation:**
```typescript
export async function initializeUserSubcollections(
  db: admin.firestore.Firestore,
  universityPath: string,
  userId: string
): Promise<void> {
  const subcollections = [
    'checklists',
    'availability',      // REMOVE THIS
    'requestedMeetings', // REMOVE THIS
    'meetings',          // REMOVE THIS
    'notes',
    'ratings'
  ];
```

**New Implementation:**
- Remove meetings, availability, and requestedMeetings from subcollection initialization

#### 3. **Potential Updates Needed**

##### `/lib/services/dashboard_data_service.dart`
- Check if it queries meeting subcollections directly
- Update to use MeetingService methods instead

##### `/lib/services/local_database_service.dart`
- If syncing meetings/availability, update sync paths

##### `/lib/services/local_to_firestore_service.dart`
- Update sync logic if handling meetings/availability

##### `/lib/services/mock_data_generator.dart`
- Update mock data generation to create in top-level collections

#### 4. **Additional Critical Files Found**

##### **Firestore Security Rules**
- `/firestore.rules`
  - Update meeting collection rules
  - Remove availability subcollection rules
  - Update to use new document structure

##### **Local Database Schema**
- `/lib/database/database_helper.dart`
  - Update meetings table schema if needed
  - Ensure availability_id column exists
  - Update sync triggers

##### **Dashboard Aggregation Service**
- `/lib/services/dashboard_data_service.dart`
  - Update meeting count queries
  - Fix upcoming meetings aggregation
  - Update meeting statistics

##### **Progress Reports Integration**
- `/lib/screens/web/shared/web_progress_reports/web_progress_reports_screen.dart`
  - Meeting frequency charts need new queries
  - Attendance tracking updates
  - Meeting history analysis

##### **Offline Sync Service**
- `/lib/services/local_to_firestore_service.dart`
  - Update sync paths for meetings
  - Handle availability sync
  - Update conflict resolution

#### 5. **Files That DON'T Need Changes**
These files use MeetingService and will work automatically after service updates:
- `/lib/screens/web/shared/web_schedule_meeting/web_schedule_meeting_screen.dart`
- `/lib/screens/web/mentor/web_mentor_dashboard/web_mentor_dashboard_screen.dart`
- `/lib/screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart`
- `/lib/screens/mobile/shared/schedule_meeting_screen.dart`
- `/lib/models/meeting.dart`
- `/lib/models/availability.dart`

### Migration Script Locations

Create new migration scripts at:
- `/functions/src/migrations/meetings-availability-migration.ts`
- `/migration-scripts/migrate-meetings-availability.dart` (for Flutter)

### Detailed Code Changes

#### Example: Updated MeetingService.dart
```dart
class MeetingService {
  // Helper method to get document ID from Firebase UID
  Future<String> getUserDocIdFromUid(String uid) async {
    final QuerySnapshot userQuery = await firestore
        .collection('$universityPath/data/users')
        .where('firebase_uid', '==', uid)
        .limit(1)
        .get();
    
    if (userQuery.docs.isEmpty) {
      throw Exception('User not found for UID: $uid');
    }
    
    return userQuery.docs.first.id;
  }
  
  // Updated meeting query
  Stream<List<Meeting>> subscribeToMeetings(String userId) {
    return firestore
        .collection('$universityPath/data/meetings')
        .where('mentor_uid', '==', userId)
        .where('start_time', '>=', DateTime.now())
        .orderBy('start_time')
        .snapshots()
        .asyncMap((snapshot) async {
          // Also get meetings where user is mentee
          final menteeQuery = await firestore
              .collection('$universityPath/data/meetings')
              .where('mentee_uid', '==', userId)
              .where('start_time', '>=', DateTime.now())
              .get();
          
          // Combine results
          final allDocs = [...snapshot.docs, ...menteeQuery.docs];
          return allDocs.map((doc) => Meeting.fromFirestore(doc)).toList();
        });
  }
}
```

#### Example: Updated meetings/management.ts
```typescript
export const createMeeting = functions.https.onCall(async (data, context) => {
  // ... validation code ...
  
  // Get user document IDs
  const mentorDoc = await getUserDocByUid(data.mentorId);
  const menteeDoc = await getUserDocByUid(data.menteeId);
  
  // Generate human-readable meeting ID
  const timestamp = Math.floor(new Date(data.startTime).getTime() / 1000);
  const meetingId = `${mentorDoc.id}__${menteeDoc.id}__${timestamp}`;
  
  const meetingData = {
    id: meetingId,
    mentor_doc_id: mentorDoc.id,
    mentee_doc_id: menteeDoc.id,
    mentor_uid: data.mentorId,
    mentee_uid: data.menteeId,
    mentor_name: mentorDoc.data().name,
    mentee_name: menteeDoc.data().name,
    // ... rest of meeting data
  };
  
  // Single write to university collection only
  await db.doc(`${universityPath}/data/meetings/${meetingId}`).set(meetingData);
  
  // NO LONGER write to subcollections
  // REMOVE: await mentorRef.collection('meetings').doc(meetingId).set(...)
  // REMOVE: await menteeRef.collection('meetings').doc(meetingId).set(...)
  
  return { success: true, meetingId };
});
```

## Timeline and Rollout

### Week 1-2: Development
- Update cloud functions
- Create migration scripts
- Update service layer

### Week 3: Testing
- Test migration on development data
- Verify all queries work correctly
- Performance testing

### Week 4: Production Migration
- Run migration during low-usage period
- Monitor for issues
- Quick rollback if needed

### Week 5: Cleanup
- Remove old code paths
- Update documentation
- Performance optimization

## Success Metrics

1. **Performance Improvements**
   - 50% reduction in Firestore reads
   - 60% reduction in write operations
   - Faster query response times

2. **Code Simplification**
   - Remove 500+ lines of synchronization code
   - Simplify security rules by 40%
   - Reduce service layer complexity

3. **Cost Reduction**
   - Lower Firestore usage costs
   - Reduced bandwidth usage
   - Fewer cloud function invocations

## Risk Mitigation

1. **Data Loss Prevention**
   - Complete backup before migration
   - Incremental migration approach
   - Verification at each step

2. **Downtime Minimization**
   - Feature flags for gradual rollout
   - Parallel running of old/new systems
   - Quick rollback capability

3. **User Impact**
   - Transparent migration
   - No UI changes required initially
   - Maintain backwards compatibility during transition

## Additional Considerations After Double-Check

### Critical Items Not in Original Plan:

1. **Firestore Security Rules Update**
   - Must update `/firestore.rules` to match new structure
   - Remove subcollection access rules
   - Add proper validation for new fields

2. **Local SQLite Database**
   - Schema already supports meetings/availability
   - Sync logic in `local_to_firestore_service.dart` must be updated
   - Offline functionality depends on this

3. **Dashboard Data Aggregation**
   - `dashboard_data_service.dart` directly queries meetings
   - Progress reports analyze meeting patterns
   - All aggregation queries need updates

4. **Missing requestedMeetings Migration**
   - Need to migrate existing `requestedMeetings` data
   - Convert to meetings with `status: 'pending'`
   - Clean up obsolete subcollections

5. **Future Enhancements to Consider**
   - Meeting reminders/notifications (not yet implemented)
   - Calendar export functionality (not found)
   - Timezone handling (currently missing)
   - Conflict detection improvements

### Final Checklist:
- [x] Create migration script (meetings-availability-migration.ts)
- [x] Update meeting service to modular structure
- [ ] Modify cloud functions (remove subcollection writes)
- [ ] Update Firestore security rules
- [ ] Modify dashboard aggregation queries
- [ ] Update offline sync logic
- [ ] Migrate existing requestedMeetings data
- [ ] Update progress report queries
- [ ] Test all user flows
- [ ] Verify data integrity
- [ ] Clean up old subcollections

## Implementation Progress

### ✅ Completed Tasks

#### 1. **Migration Script Created**
- **File**: `/functions/src/migrations/meetings-availability-migration.ts`
- **Features**:
  - Migrates meetings from user subcollections to top-level collection
  - Converts availability from nested slots to individual documents
  - Migrates requestedMeetings to meetings with `status: 'pending'`
  - Includes dry-run mode for safe testing
  - Generates human-readable IDs: `mentorDocId__menteeDocId__timestamp`
  - Tracks migration statistics and errors
- **Exported Functions**:
  - `migrateAllMeetingsAndAvailability` - Main migration function
  - `cleanupMeetingSubcollections` - Cleanup function after migration

#### 2. **Modular Meeting Service Structure (Dart)**
Created a fully modular structure at `/lib/services/meeting/`:

```
meeting/
├── meeting_service.dart              # Main facade (200 lines)
├── repositories/
│   ├── meeting_repository.dart       # Meeting CRUD (350 lines)
│   ├── availability_repository.dart  # Availability CRUD (280 lines)
│   └── user_repository.dart         # User lookups (120 lines)
├── managers/
│   ├── stream_manager.dart          # Stream management (130 lines)
│   └── cache_manager.dart           # Caching logic (110 lines)
└── utils/
    ├── meeting_constants.dart       # Constants (40 lines)
    └── meeting_helpers.dart         # Helpers (90 lines)
```

#### 3. **Modular Cloud Functions Structure (TypeScript)**
Created modular structure at `/functions/src/meetings/`:

```
meetings/
├── index.ts                         # Exports all functions
├── create-meeting.ts                # Meeting creation without subcollections
├── update-meeting.ts                # Meeting updates
├── meeting-status.ts                # Accept/reject/cancel operations
├── availability-management.ts       # Availability CRUD operations
├── request-meeting.ts               # Meeting request function
└── utils/
    └── meeting-helpers.ts           # Helper functions
```

**Key Changes**:
- No more subcollection writes
- Uses top-level collections only
- Human-readable IDs throughout
- Proper TypeScript structure

#### 4. **Database Utils Updated**
- **File**: `/functions/src/utils/database.ts`
- **Change**: Removed meetings, availability, and requestedMeetings from subcollection initialization
- Now only initializes: checklists, notes, ratings

#### 5. **Functions Index Updated**
- **File**: `/functions/src/index.ts`
- **Change**: Updated imports to use new modular meetings structure
- Exports migration functions for easy access

#### 6. **Firestore Security Rules Updated**
- **File**: `/firestore.rules`
- **Changes**:
  - Added new rules for top-level `meetings` collection
  - Added new rules for top-level `availability` collection
  - Updated user subcollection rules to exclude meetings/availability/requestedMeetings
  - Added proper permissions for each user role
  - Meetings: participants can read/update, coordinators have full access
  - Availability: mentors own their slots, mentees can book, anyone can read

### 🚧 Remaining Tasks

#### 1. **Dashboard Data Service** (In Progress)
- **File**: `/lib/services/dashboard_data_service.dart`
- **Changes Needed**:
  - Update `_getMenteeUpcomingMeetings()` to query top-level meetings collection
  - Remove any subcollection queries
  - Update meeting count aggregations
  - Fix meeting statistics queries

#### 2. **Progress Reports Service**
- **File**: `/lib/screens/web/shared/web_progress_reports/`
- **Changes Needed**:
  - Update meeting frequency queries
  - Fix attendance tracking to use top-level collection
  - Update meeting history analysis

#### 3. **Offline Sync Service**
- **File**: `/lib/services/local_to_firestore_service.dart`
- **Changes Needed**:
  - Update sync paths for meetings
  - Remove subcollection sync logic
  - Add sync for availability collection

#### 4. **Import Existing Meeting Service**
- **Current**: `/lib/services/meeting_service.dart`
- **New**: `/lib/services/meeting/meeting_service.dart`
- **Action**: Update all imports throughout the codebase

#### 5. **Deploy Cloud Functions**
- Build TypeScript functions
- Deploy new modular structure
- Ensure old endpoints still work during transition

#### 6. **Run Migration**
- Test migration script on development data
- Run with dry-run mode first
- Execute actual migration
- Verify data integrity
- Run cleanup script after verification

### 📋 Quick Reference - What Changed

**Before:**
```
/users/{userId}/meetings/{meetingId}
/users/{userId}/availability/{availId}
/users/{userId}/requestedMeetings/{meetingId}
```

**After:**
```
/meetings/{mentorDocId}__{menteeDocId}__{timestamp}
/availability/{mentorDocId}__{timestamp}
(requestedMeetings merged into meetings with status: 'pending')
```

**Meeting Document Structure:**
```javascript
{
  id: "Dasarathi_Narayanan__Emerald_Nash__1704835200",
  mentor_doc_id: "Dasarathi_Narayanan",
  mentee_doc_id: "Emerald_Nash",
  mentor_uid: "Qq4dMq...",
  mentee_uid: "Xn5pRt...",
  mentor_name: "Dasarathi Narayanan",
  mentee_name: "Emerald Nash",
  // ... rest of fields
}
```

### 🚀 Deployment Checklist

- [ ] Update all service imports to new modular structure
- [ ] Deploy updated cloud functions
- [ ] Deploy Firestore security rules
- [ ] Update dashboard queries
- [ ] Update progress report queries
- [ ] Update offline sync logic
- [ ] Run migration script (dry-run first)
- [ ] Verify data integrity
- [ ] Run cleanup script
- [ ] Monitor for errors
- [ ] Update documentation