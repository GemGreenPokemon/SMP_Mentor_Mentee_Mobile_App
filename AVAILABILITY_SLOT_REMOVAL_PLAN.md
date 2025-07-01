# Availability Slot Removal on Meeting Cancellation/Rejection

## Problem Statement

### Current Behavior
When a mentor cancels or rejects a meeting, the system currently:
1. Updates the meeting status to 'cancelled' or 'rejected'
2. **Unbooks** the availability slot by clearing the booking fields
3. Leaves the slot available for immediate rebooking by another mentee

### The Issue
This behavior doesn't align with real-world scenarios:
- If a mentor cancels/rejects a meeting, it typically means they **cannot meet at that time**
- Student mentors have dynamic schedules - classes change, assignments arise, personal matters occur
- Simply unbooking the slot allows another mentee to immediately book it, potentially creating the same conflict
- The mentor would have to cancel/reject again, creating a poor experience for everyone

### User Impact
- **Mentors**: Forced to repeatedly reject meetings for times they're not actually available
- **Mentees**: Frustration from booking slots that get rejected
- **System**: Unnecessary cycles of booking and rejection

## Solution

### Proposed Behavior
When a mentor cancels or rejects a meeting:
1. Update the meeting status as before
2. **DELETE** the availability slot entirely from the system
3. The time slot disappears from the mentor's available times
4. Mentor can manually re-add availability when their schedule permits

### Benefits
1. **Accurate Availability**: Calendar reflects mentor's true availability
2. **Prevents Rebooking Issues**: No risk of immediate rebooking of unsuitable times
3. **Acknowledges Reality**: Recognizes that student schedules are dynamic
4. **Better UX**: Fewer rejections and cancellations overall

## Implementation Pathways

### Phase 1: Core Functionality Changes

#### 1.1 Modify `cancelMeeting` Function
**File**: `/functions/src/meetings/meeting-status.ts`

**Current Code** (lines 72-89):
```typescript
// If meeting had an availability slot, unbook it
if (meeting.availability_id) {
  try {
    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    await availabilityCollection.doc(meeting.availability_id).update({
      is_booked: false,
      booked_by_uid: null,
      booked_by_doc_id: null,
      booked_by_name: null,
      meeting_id: null,
      booked_at: null,
      updated_at: FieldValue.serverTimestamp()
    });
    console.log(`Unbooked availability slot ${meeting.availability_id}`);
  } catch (error) {
    console.error(`Failed to unbook availability slot: ${error}`);
  }
}
```

**New Code**:
```typescript
// If meeting had an availability slot, remove it entirely
if (meeting.availability_id) {
  try {
    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    await availabilityCollection.doc(meeting.availability_id).delete();
    console.log(`Deleted availability slot ${meeting.availability_id} after meeting cancellation/rejection`);
  } catch (error) {
    console.error(`Failed to delete availability slot: ${error}`);
    // Log but don't fail the overall operation
  }
}
```

#### 1.2 Modify `rejectMeeting` Function
**File**: `/functions/src/meetings/meeting-status.ts`

**Current Code** (lines 224-241):
```typescript
// If meeting had an availability slot, unbook it
if (meeting.availability_id) {
  try {
    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    await availabilityCollection.doc(meeting.availability_id).update({
      is_booked: false,
      booked_by_uid: null,
      booked_by_doc_id: null,
      booked_by_name: null,
      meeting_id: null,
      booked_at: null,
      updated_at: FieldValue.serverTimestamp()
    });
    console.log(`Unbooked availability slot ${meeting.availability_id} after meeting rejection`);
  } catch (error) {
    console.error(`Failed to unbook availability slot: ${error}`);
  }
}
```

**New Code**:
```typescript
// If meeting had an availability slot, remove it entirely
if (meeting.availability_id) {
  try {
    const availabilityCollection = getUniversityCollection(universityPath, 'availability');
    await availabilityCollection.doc(meeting.availability_id).delete();
    console.log(`Deleted availability slot ${meeting.availability_id} after meeting rejection`);
  } catch (error) {
    console.error(`Failed to delete availability slot: ${error}`);
    // Log but don't fail the overall operation
  }
}
```

### Phase 2: UI Updates

#### 2.1 Scheduler Real-time Updates
The web scheduler should automatically reflect the removed availability slots through existing real-time listeners. No changes needed if streams are working properly.

#### 2.2 Visual Feedback
Consider adding a temporary notification when slots are removed:
- "Availability slot removed after meeting cancellation"
- This helps mentors understand what happened

### Phase 3: Future Enhancements (Optional)

#### 3.1 Bulk Re-add Availability
- Add a feature for mentors to quickly re-add previously removed slots
- "Copy from previous week" functionality

#### 3.2 Availability History
- Track removed slots for analytics
- Help mentors identify patterns in their scheduling conflicts

## Testing Plan

### Test Scenarios
1. **Cancel a confirmed meeting** → Verify slot is deleted
2. **Reject a pending meeting** → Verify slot is deleted
3. **Cancel meeting without availability_id** → Verify no errors occur
4. **Multiple rapid cancellations** → Verify all slots are properly removed
5. **UI Updates** → Verify scheduler reflects removed slots in real-time

### Edge Cases
1. Availability slot already deleted (double-delete attempt)
2. Network issues during deletion
3. Concurrent operations on the same slot

## Rollback Plan

If issues arise, the changes can be easily reverted:
1. Change `.delete()` back to `.update()` with unbooking fields
2. Redeploy functions
3. No data migration needed as meetings retain their availability_id reference

## Success Metrics

1. **Fewer repeat rejections** of the same time slots
2. **Improved mentor satisfaction** with scheduling control
3. **Reduced mentee frustration** from rejected bookings
4. **Cleaner availability data** reflecting true mentor availability

## Timeline

- **Immediate**: Implement core function changes (Phase 1)
- **Next Sprint**: Monitor and gather feedback
- **Future**: Consider Phase 3 enhancements based on user feedback

## Update: Array-Based Availability Structure

During implementation, we discovered that availability is stored as arrays within documents, not as individual documents. The implementation has been updated to handle this structure:

### Availability Storage Format
- Each day's availability is stored as one document
- Document ID format: `{mentorDocId}_{date}` (e.g., `Emerald_Nash_2025-07-04`)
- Each document contains an array of time slots
- Individual slots are identified by: `{docId}_slot_{index}`

### Updated Implementation
The code now:
1. Parses the availability ID to extract document ID and slot index
2. Retrieves the availability document
3. Removes the specific slot from the array
4. Updates the document with the modified array

This ensures that when meetings are cancelled/rejected, the specific time slot is removed from the mentor's availability.

---

*This change acknowledges that student mentors have dynamic schedules and need flexibility in managing their availability. By removing slots entirely when meetings are cancelled or rejected, we create a more honest and efficient scheduling system.*