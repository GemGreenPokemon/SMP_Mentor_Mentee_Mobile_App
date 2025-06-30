# Firebase UID Propagation Fix

## Problem Description
When a mentor schedules a meeting before a mentee has created their account, the meeting document uses the mentee's document ID as a placeholder for the `mentee_uid` field. Once the mentee registers and receives their Firebase UID, the meeting document still contains the placeholder, causing permission checks to fail when the mentee tries to accept/decline the meeting.

### Example:
- Meeting created with: `mentee_uid: "Dasarathi_Narayanan"` (document ID placeholder)
- Mentee registers and gets: `firebase_uid: "yRA1aFIUUcbAi1JKI2R5c7pWngil"`
- Permission check fails because: `"yRA1aFIUUcbAi1JKI2R5c7pWngil" !== "Dasarathi_Narayanan"`

## Solution Implemented

### Files Modified:

1. **`/functions/src/auth/triggers.ts`**
   - Modified `setClaimsOnRegistration` function (lines 320-384)
   - Modified `syncClaimsOnLogin` function (lines 123-179)
   - Added logic to update meetings when user gets `firebase_uid` for the first time

2. **`/functions/src/users/acknowledgment.ts`**
   - Modified `submitMenteeAcknowledgment` function (lines 223-261)
   - Added logic to update meetings after mentee completes acknowledgment

### Implementation Details:

The solution queries for meetings where:
- `mentee_doc_id` equals the user's document ID AND
- `mentee_uid` equals the user's document ID (indicating it's still a placeholder)

Then updates the `mentee_uid` to the actual Firebase UID.

```typescript
// Example from acknowledgment.ts
const menteeMeetings = await meetingsCollection
  .where('mentee_doc_id', '==', userDocId)
  .where('mentee_uid', '==', userDocId)  // Only matches placeholders
  .get();

if (!menteeMeetings.empty) {
  const batch = admin.firestore().batch();
  
  menteeMeetings.forEach(doc => {
    batch.update(doc.ref, { 
      mentee_uid: userId,  // Update to real Firebase UID
      updated_at: FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
}
```

## How to Apply to Other Collections

### 1. Messages/Conversations Collection

If the conversations collection has similar issues with placeholder UIDs:

```typescript
// Add to the same functions (setClaimsOnRegistration, syncClaimsOnLogin, submitMenteeAcknowledgment)

// For conversations where user is participant
const conversationsCollection = admin.firestore()
  .collection(universityPath)
  .doc('data')
  .collection('conversations');

// Update participant details
const conversations = await conversationsCollection
  .where('participants', 'array-contains', userDocId)
  .get();

if (!conversations.empty) {
  const batch = admin.firestore().batch();
  
  conversations.forEach(doc => {
    const data = doc.data();
    
    // Update participant_details object
    if (data.participant_details && data.participant_details[userDocId]) {
      batch.update(doc.ref, {
        [`participant_details.${userDocId}.uid`]: userId,
        updated_at: FieldValue.serverTimestamp()
      });
    }
  });
  
  await batch.commit();
}
```

### 2. Availability Collection

If availability slots store UIDs:

```typescript
// For mentor availability slots
if (userType === 'mentor') {
  const availabilityCollection = admin.firestore()
    .collection(universityPath)
    .doc('data')
    .collection('availability');
  
  const mentorAvailability = await availabilityCollection
    .where('mentor_doc_id', '==', userDocId)
    .where('mentor_uid', '==', userDocId)  // Placeholder check
    .get();
  
  // Update logic similar to meetings
}
```

### 3. General Pattern for Any Collection

1. **Identify collections** that store user references as UIDs
2. **Check for placeholder patterns** where UID equals document ID
3. **Add update logic** in these three locations:
   - `auth/triggers.ts` → `setClaimsOnRegistration` (for new registrations)
   - `auth/triggers.ts` → `syncClaimsOnLogin` (for existing users)
   - `users/acknowledgment.ts` → `submitMenteeAcknowledgment` (for mentee flow)

4. **Use compound queries** to find only documents with placeholders:
   ```typescript
   .where('user_doc_id', '==', userDocId)
   .where('user_uid', '==', userDocId)  // Only matches if UID is still placeholder
   ```

5. **Use batch operations** for efficiency
6. **Include error handling** but don't fail the main operation
7. **Add detailed logging** for debugging

## Testing Procedure

1. Create test data before user registration (meeting, message, etc.)
2. Register the user
3. Check Firebase Functions logs for update messages
4. Verify the UIDs have been updated in Firestore
5. Test that permission-based operations now work

## Important Notes

- This fix is only needed for collections that store Firebase UIDs
- The compound query ensures we don't overwrite already-correct UIDs
- The fix runs automatically during the user registration/acknowledgment flow
- In production, this issue only occurs once per user (when they first register)
- The fix is idempotent - running it multiple times is safe