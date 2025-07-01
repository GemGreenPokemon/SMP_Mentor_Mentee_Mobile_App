# Meeting Status Flow Fix

**Status**: ✅ FIXED (6/30/25)

## Current Understanding of Meeting Status Flow

### 1. Meeting Creation
- **Mentor** can create a meeting → Status: `pending` (waiting for mentee response)
- **Mentee** can request a meeting → Status: `pending` (waiting for mentor response)

### 2. From Pending Status

#### Actions Available:
- **Confirm** → Status: `confirmed`
  - Either party can confirm depending on who created the meeting
  
- **Reject** → Status: `rejected`
  - Either party can reject
  - **No reason required** (meeting was never confirmed)
  - Fields added: `rejected_at`, `rejected_by`

### 3. From Confirmed Status

#### Actions Available:
- **Cancel** → Status: `cancelled`
  - Both mentee and mentor can cancel
  - **Reason required from both** (considerate since meeting was already confirmed)
  - Fields added: `cancelled_at`, `cancelled_by`, `cancellation_reason`

- **Reschedule** → Status: `rescheduled`
  - **Only mentor can reschedule**
  - **Only available for confirmed meetings**
  - Cannot reschedule a pending meeting

## Current Code Issues

### Issue 1: Wrong Status for Pending Meeting Rejection
**Problem**: When rejecting a pending meeting, the code uses `cancelled` status instead of `rejected`

**Location**: `/functions/src/meetings/meeting-status.ts` (cancelMeeting function)
- Line 49: Sets status to 'cancelled' for all cases
- Should differentiate between reject (from pending) and cancel (from confirmed)

**Fields Being Set Incorrectly**:
```typescript
// Current (wrong for pending meetings):
status: 'cancelled',
cancelled_at: FieldValue.serverTimestamp(),
cancelled_by: authContext.uid,
cancellation_reason: reason || null,

// Should be (for pending meetings):
status: 'rejected',
rejected_at: FieldValue.serverTimestamp(),
rejected_by: authContext.uid,
// No rejection_reason field
```

### Issue 2: Single Function Handling Multiple Actions
**Problem**: The `cancelMeeting` function is being used for both:
- Rejecting pending meetings
- Cancelling confirmed meetings

**Solution**: Either:
1. Create separate functions: `rejectMeeting` and `cancelMeeting`
2. Or add logic to check current status and apply appropriate updates

### Issue 3: Frontend Calling Wrong Function
**Problem**: When declining a pending meeting, the frontend calls `deleteMeeting` which maps to `cancelMeeting`

**Locations**:
- `/lib/screens/web/mentee/web_mentee_dashboard/web_mentee_dashboard_screen.dart`
- `/lib/screens/web/mentor/web_mentor_dashboard/web_mentor_dashboard_screen.dart`

## Proposed Fix

### 1. Create Proper Rejection Logic
- Check meeting's current status before updating
- If status is `pending` → use rejection fields
- If status is `confirmed` → use cancellation fields

### 2. Update Field Names
- For pending → rejected: `rejected_at`, `rejected_by` (no reason)
- For confirmed → cancelled: `cancelled_at`, `cancelled_by`, `cancellation_reason`

### 3. Enforce Business Rules
- Reschedule only available for confirmed meetings
- Cancel requires reason when meeting was confirmed
- Reject doesn't require reason (meeting was never confirmed)

## Files Modified ✅

1. **Backend**: `/functions/src/meetings/meeting-status.ts`
   - ✅ Updated `cancelMeeting` to check current status
   - ✅ Apply appropriate fields based on status:
     - If `pending` → sets `rejected` status with `rejected_at`, `rejected_by`
     - If `confirmed` → sets `cancelled` status with `cancelled_at`, `cancelled_by`, `cancellation_reason`

2. **Frontend**: No changes needed
   - Dashboard already uses "Decline" terminology for pending meetings
   - Appropriate for the rejection action

## Implementation Details

### Changes Made to `meeting-status.ts`:

```typescript
// Check if meeting is pending or confirmed
const isPending = meeting.status === 'pending';

const updates: any = {
  status: isPending ? 'rejected' : 'cancelled',
  updated_at: FieldValue.serverTimestamp(),
  updated_by: authContext.uid
};

if (isPending) {
  // Rejection fields (no reason needed for pending meetings)
  updates.rejected_at = FieldValue.serverTimestamp();
  updates.rejected_by = authContext.uid;
} else {
  // Cancellation fields (reason required for confirmed meetings)
  updates.cancelled_at = FieldValue.serverTimestamp();
  updates.cancelled_by = authContext.uid;
  updates.cancellation_reason = reason || null;
}
```

## Database Schema Updated

The database schema has been updated (6/30/25) to document all dynamic fields that can appear on meeting documents based on status changes. See `database_schema.md` for complete field documentation.

## ⚠️ Frontend Updates Still Needed

While the backend now properly handles reject/cancel/reschedule logic, the frontend is missing key functionality:

### Missing Mentor Dashboard Features:
1. **Cancel Meeting** - No way to cancel a confirmed meeting
2. **Reschedule Meeting** - No way to reschedule a confirmed meeting
3. These options should appear for confirmed meetings where the mentor is a participant

### Missing Mentee Dashboard Features:
1. **Cancel Meeting** - No way to cancel a confirmed meeting (with reason)
2. This option should appear for confirmed meetings where the mentee is a participant

### Current Frontend State:
- ✅ Mentees can accept/decline pending meetings
- ✅ Mentors can accept/decline pending meetings
- ❌ No one can cancel confirmed meetings
- ❌ Mentors cannot reschedule meetings

### Implementation Notes for Future:
1. Add action buttons for confirmed meetings based on user role
2. For cancellation: Show dialog to collect cancellation reason
3. For reschedule: Show date/time picker to select new time
4. Update meeting cards to show appropriate actions based on:
   - Meeting status (pending vs confirmed)
   - User role (mentor vs mentee)
   - User's relationship to meeting (creator vs recipient)